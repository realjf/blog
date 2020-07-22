---
title: "简单的基于Elasticsearch-php API的封装 Library Elasticsearch Api Client"
date: 2020-06-10T11:56:47+08:00
keywords: ["elasticsearch"]
categories: ["elasticsearch"]
tags: ["elasticsearch"]
series: [""]
draft: false
toc: false
related:
  threshold: 80
  includeNewer: false
  toLower: false
  indices:
  - name: keywords
    weight: 100
  - name: tags
    weight: 90
  - name: categories
    weight: 50
  - name: date
    weight: 10
---

```php
abstract class libEsBase
{
    protected $__index = "";
    protected $__type = "";

    const MAX_RESULT_WINDOW = 10000; // from + size <= max_result_window

    /**
     * 定义结构
     * @return array
     */
    abstract protected function __getMapping();


    /**
     * @var \Elasticsearch\Client
     */
    protected $_es = null;

    public function __construct()
    {
        $this->_es = "your elasticsearch-php api client";
    }

    /**
     * @return array
     */
    protected function __runBefore()
    {
        if(!$this->checkEsAlive()){
            return [FALSE, "Elasticsearch not alive"];
        }
        list($check, $msg) = $this->checkIndex();
        if(!$check){
            // 索引不存在
            list($check, $msg) = $this->createIndex();
            if(!$check){
                return [FALSE, $msg];
            }
            sleep(3); // 等待index状态更新
        }
        list($check, $msg) = $this->getMapping();
        if(!$check){
            // 创建mapping
            list($check, $msg) = $this->createMapping();
            if(!$check){
                return [FALSE, $msg];
            }
        }

        return [TRUE, ""];
    }

    /**
     * @return string
     */
    protected function _getIndex()
    {
        return $this->__index;
    }

    /**
     * 创建索引
     * @return array
     */
    public function createIndex()
    {
        try{
            $param = [
                'index' => $this->_getIndex(),
                'body' => [],
            ];
            $result = $this->_es->indices()->create($param);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        return [$result['acknowledged'], $result];
    }

    /**
     * 创建mapping
     * @return array
     */
    public function createMapping()
    {
        try{
            $param = [
                'index' => $this->_getIndex(),
                'type' => $this->__type,
                'body' => [
                    $this->__type => $this->__getMapping(),
                ],
            ];
            $result = $this->_es->indices()->putMapping($param);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        return [$result['acknowledged'], $result];
    }

    /**
     * 删除索引
     * @return array
     */
    public function deleteIndex($index = "")
    {
        try{
            $param = [
                'index' => $index ?: $this->_getIndex(),
            ];
            $result = $this->_es->indices()->delete($param);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        return [$result['acknowledged'], $result];
    }

    /**
     * 获取mapping
     * @return array
     */
    public function getMapping()
    {
        try{
            $param = [
                'index' => $this->_getIndex(),
                'type' => $this->__type,
            ];
            $result = $this->_es->indices()->getMapping($param);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        if(!$result){
            return [FALSE, $result];
        }
        return [TRUE, $result];
    }

    /**
     * 查询单条数据
     * @param $id
     * @return array
     */
    public function getById($id)
    {
        if(!$id){
            return [FALSE, ""];
        }
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
            'id' => $id,
        ];
        try{
            $result = $this->_es->get($params);
        } catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        $data = [];
        if($result['hits']){
            $data = $result['hits'];
        }
        return [TRUE, $data];
    }

    public function scroll($query, $page, $limit)
    {
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
            'size' => $limit,
            'scroll' => "1m", // 存活时间
        ];

        if(!$query){
            $params['body']['query'] = [
                'match_all' => new \stdClass(),
            ];
        }else{
            $params['body']['query'] = $query;
        }
        $data = [
            'total' => 0,
            'data' => [],
        ];
        try{
            $result = $this->_es->search($params);
            $scroll_id = $result["_scroll_id"];

            if($page != 1){
                $i = 1;
                while($i < $page) {
                    $result = [];
                    $response = $this->_es->scroll([
                        "scroll_id" => $scroll_id,
                        "scroll" => "1m"
                    ]);
                    if(count($response['hits']['hits']) > 0){
                        $scroll_id = $response["_scroll_id"];
                        $result = $response;
                    }else{
                        break;
                    }
                    $i++;
                }
            }
        } catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }

        if($result['hits']['total'] > 0){
            $data['total'] = $result['hits']['total'];
            foreach ($result['hits']['hits'] as $v){
                $data['data'][] = $v['_source'];
            }
        }
        return [TRUE, $data];
    }

    /**
     * 统计总条数
     * @return array
     */
    public function count()
    {
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
        ];
        try{
            $result = $this->_es->count($params);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        $data['total'] = 0;
        if($result['count'] >= 0){
            return [TRUE, $result['count']];
        }
        return [FALSE, $result];
    }

    /**
     * 查询
     * @param $query
     * @param int $page
     * @param int $limit
     * @param array $order
     * @return array
     */
    public function search($query, $page = 1, $limit = 20, $order = ['date' => 'desc'], $aggs = [])
    {
        list($check, $msg) = $this->__runBefore();
        if(!$check){
            return [FALSE, $msg];
        }
        $from = max(0, $page * $limit - $limit);
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
        ];
        $params['body']['sort'] = $order;
        $params['body']['from'] = $from;
        $params['body']['size'] = $limit;
        if(!$query){
            $params['body']['query'] = [
                'match_all' => new \stdClass(),
            ];
        }else{
            $params['body']['query'] = $query;
        }
        if($aggs){
            $params['body'] = array_merge($params['body'], $aggs);
        }
        if($from + $limit > self::MAX_RESULT_WINDOW){
            return [FALSE, "超出限制范围"];
        }
        try{
            $result = $this->_es->search($params);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        $data = [
            'total' => 0,
            'data' => [],
            'aggs' => [],
        ];
        if($result['hits']['total'] > 0){
            $data['total'] = $result['hits']['total'];
            foreach ($result['hits']['hits'] as $v){
                $data['data'][] = $v['_source'];
            }
        }
        if($aggs){
            $data['aggs'] = $result['aggregations'];
        }
        return [TRUE, $data];
    }



    /**
     * 检查索引是否存在
     * @return array
     */
    public function checkIndex()
    {
        $params = [
            'index' => $this->_getIndex(),
        ];
        try{
            $data = $this->_es->indices()->exists($params);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        return [$data, ""];
    }

    /**
     * 检查es是否存活
     * @return bool
     */
    public function checkEsAlive()
    {
        return $this->_es->ping();
    }

    /**
     * 插入单条数据
     * @param $id
     * @param $data
     * @return array
     */
    public function insert($id, $data)
    {
        list($check, $msg) = $this->__runBefore();
        if(!$check){
            return [FALSE, $msg];
        }
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
        ];
        if($id){    // 如果不设置 id，则es会自动生成，建议设置id
            $params['id'] = intval($id);
        }
        $params['body'] = $data;
        try{
            $result = $this->_es->index($params);
        } catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        return [TRUE, $result];
    }

    /**
     * 批量插入数据
     * @param $data
     * @return array
     */
    abstract public function bulk($data);

    /**
     * 根据id批量获取
     * @param $ids
     * @return array|bool
     */
    public function getByIds($ids)
    {
        $ids = \clsTools::filterIds($ids, 0);
        if(!$ids){
            return [FALSE, "empty ids"];
        }
        $params = [
            "docs" => [],
        ];
        foreach ($ids as $id){
            $params["docs"][] = [
                'index' => $this->_getIndex(),
                'type' => $this->__type,
                "id" => $id,
            ];
        }

        try{
            $result = $this->_es->mget($params);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        $data = [];
        if($result['hits']){
            $data = $result['hits'];
        }
        return [TRUE, $data];
    }

    /**
     * 根据id删除
     * @param $id
     * @return array|bool
     */
    public function deleteById($id)
    {
        $id = intval($id);
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
            "id" => $id,
        ];
        try{
            $result = $this->_es->delete($params);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }

        if($result['found']){
            return [TRUE, $result];
        }
        return [FALSE, $result];
    }

    /**
     * 根据查询条件删除
     * @param $query
     * @return array
     */
    public function deleteByQuery($query)
    {
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
            "body" => [
                'query' => $query,
            ],
        ];
        try{
            $result = $this->_es->deleteByQuery($params);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }
        if($result['found']){
            return [TRUE, $result];
        }
        return [FALSE, $result];
    }

    /**
     * 根据id更新
     * @param $id
     * @param $data
     * @return array
     */
    public function updateById($id, $data)
    {
        $id = intval($id);
        $params = [
            'index' => $this->_getIndex(),
            'type' => $this->__type,
            "id" => $id,
            "body" => [
                "doc" => $data,
            ],
        ];
        try{
            $result = $this->_es->update($params);
        }catch (\Exception $e){
            return [FALSE, $e->getMessage()];
        }

        if($result['result'] == "updated"){
            return [TRUE, $result];
        }
        if($result["result"] == "noop"){
            // 空操作
            return [TRUE, $result];
        }
        return [FALSE, $result];
    }
}
```