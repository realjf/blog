---
title: "phpExcel导出excel文件内存溢出问题 Php Excel Memory Overflow"
date: 2020-12-14T09:08:01+08:00
keywords: ["php"]
categories: ["php"]
tags: ["php", "excel"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
  includeNewer: true
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

### 背景
今天在使用phpexcel导出数据为excel格式的时候，遇到一个问题，由于数据量比较大，所以，一次性缓存在内存中导致超出php的内存限制，Excel中一个单元格在不启用缓存的情况下大概占用内存是1K。我的数据是大概31万行、9列的表格（大概279万个单元格），需要2.66GB的内存。启用缓存的话，则会降到900MB，感觉还是太大。先试下看看


### 解决
phpexcel的内存优化参数并不在phpexcel对象中，需要在phpexcel实例化之前设置
```php
$cacheMethod = PHPExcel_CachedObjectStorageFactory::cache_to_phpTemp;
$cacheSettings = array( 'memoryCacheSize' => '950MB');
PHPExcel_Settings::setCacheStorageMethod($cacheMethod,$cacheSettings);

$oExcel = new PHPExcel();
```
PHPExcel_Settings::setCacheStorageMethod() 的几个参数

- 将单元格数据序列化后保存到内存中
```php
PHPExcel_CachedObjectStorageFactory::cache_in_memory_serialized; 
```
- 将单元格序列化后再进行gzip压缩，然后保存到内存中
```php
PHPExcel_CachedObjectStorageFactory::cache_in_memory_gzip; 
```
- 缓存在临时的磁盘文件中，速度可能会慢一些
```php
PHPExcel_CachedObjectStorageFactory::cache_to_discISAM;
```
- 保存在php://temp
```php
PHPExcel_CachedObjectStorageFactory::cache_to_phpTemp; 
```
- 保存在memcache中
```php
$cacheMethod = PHPExcel_CachedObjectStorageFactory::cache_to_memcache;  
$cacheSettings = array( 'memcacheServer'  => 'localhost',  
    'memcachePort'    => 11211,  
    'cacheTime'       => 600  
);  
PHPExcel_Settings::setCacheStorageMethod($cacheMethod, $cacheSettings);
```

### 其它降低内存使用的方法

如果不需要读取Excel单元格格式，可以设置为只读取数据。
```php
$objReader = PHPExcel_IOFactory::createReader('Excel2007');
$objReader->setReadDataOnly(true);
$objPHPExcel = $objReader->load("test.xlsx”);
```
如果Excel中有多个Sheet，但是我们只需要读取其中几个，为了减少内存消耗，也可以设置。
```php
$objReader = PHPExcel_IOFactory::createReader('Excel2007');
$objReader->setLoadSheetsOnly( array("Worksheet1", "Worksheet2") );
$objPHPExcel = $objReader->load("test.xlsx”);
```
如果只需要读取Sheet中一定区域，也可以设置过滤器。

```php
class MyReadFilter implements PHPExcel_Reader_IReadFilter
{
    public function readCell($column, $row, $worksheetName = '') {
        // Read title row and rows 20 - 30
        if ($row == 1 || ($row >= 20 && $row <= 30)) {
            return true;
        }

        return false;
    }
}

$objReader = PHPExcel_IOFactory::createReader('Excel2007');
$objReader->setReadFilter( new MyReadFilter() );
$objPHPExcel = $objReader->load("test.xlsx”);
```

### 我的解决方案
我试了上面所有的方法还是不行，因为生产环境特殊要求，不能把php的内存设置过大，所以最后我只能把数据按照csv格式写入文件了，然后再用excel导入csv文件即可。这里只列出写每一行数据的函数，其他自行完成即可
```php
private function _writeLine($pFileHandle = null, $pValues = null) {
		if (is_array($pValues)) {
			// No leading delimiter
			$writeDelimiter = false;

			// Build the line
			$line = '';

			foreach ($pValues as $element) {
				// Escape enclosures
				$element = str_replace($this->_enclosure, $this->_enclosure . $this->_enclosure, $element);

				// Add delimiter
				if ($writeDelimiter) {
					$line .= $this->_delimiter;
				} else {
					$writeDelimiter = true;
				}

				// Add enclosed string
				$line .= $this->_enclosure . $element . $this->_enclosure;
			}

			// Add line ending
			$line .= $this->_lineEnding;

			// Write to file
            fwrite($pFileHandle, $line);
		} else {
			__d("Invalid data row passed to CSV writer.");
		}
	}
```
