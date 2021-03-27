
字符串常用方法
//contains()--是否包含特定的内容，返回值true/false
groovy:000> "你好".contains('好');
===> true

//size() length()--字符串数量长度
groovy:000> 'devops'.size();
===> 6
groovy:000> 'devops'.length();
===> 6

//大小写转换
groovy:000> 'devops'.toUpperCase();
===> DEVOPS
groovy:000> 'DEVOPS'.toLowerCase()
===> devops

//结尾添加或删除字符
groovy:000> 'devops'.minus('s');
===> devop
groovy:000> 'devops'.plus('66');
===> devops66

//字符串反转
groovy:000> 'DEVOPS'.reverse();
===> SPOVED

//加减符号对字符串
groovy:000> 'dev' + 'ops'
===> devops
groovy:000> 'devops' - 'ops'
===> dev

//加减符号对数字，计算器
groovy:000> 20 -5 
===> 15

//按字符分割
groovy:000> 'host1,host2,host3'.split(',');
===> [host1, host2, host3]