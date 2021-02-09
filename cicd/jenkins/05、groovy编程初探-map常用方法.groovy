map字典常用方法
[key:value]

//获取key和values
groovy:000> [name:'李彬',age:30,sex:'男',abby:'男']['name'];
===> 李彬
groovy:000> [name:'李彬',age:30,sex:'男',abby:'男']['sex'];
===> 男
groovy:000> [name:'李彬',age:30,sex:'男',abby:'男'].keySet();
===> [name, age, sex, abby]
groovy:000> [name:'李彬',age:30,sex:'男',abby:'男'].values();
===> [李彬, 30, 男, 男]

//增加和删除元素
groovy:000> [name:'李彬',age:30,sex:'男',abby:'男'] + [addr:'北京']
===> [name:李彬, age:30, sex:男, abby:男, addr:北京]

groovy:000> [name:'李彬',age:30,sex:'男',abby:'男'] - [sex:'男']
===> [name:李彬, age:30, abby:男]