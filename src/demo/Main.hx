package demo;

class Main
{
  static var TEMPLATE = "@{
  function ucwords(s) {
    var r = '';
    var arr = s.split(' ');
    for (v in arr)
      r += v.substr(0, 1).toUpperCase() + v.substr(1, v.length-1) + ' ';
    return r;
  };
  sortArray(list);
}
@{ line = '--='; }
@(line + '=--')
@ucwords(title)
@(line + '=--')

@content.substr(0, 40)...

@for(item in list) {
  * @if(item.sex == 'f') {Ms.} else {Mr.} @item.name
}
";
  static function main()
  {
	var h = {
		title   : 'erazor - the template system for haxe',
		content : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In ullamcorper felis non libero blandit facilisis. In hac habitasse platea dictumst',
		list    : [
		  { sex : 'm', name : 'Boris' },
		  { sex : 'f', name : 'Doris' },
		  { sex : 'm', name : 'John' },
		  { sex : 'f', name : 'Jane' },
		],
		repeat  : function(v, l) {
		  return StringTools.lpad('', v, l);
		},
		sortArray : function(arr) {
			arr.sort(function(a, b) {
				if (a.name == b.name)
				  return 0;
				else if (a.name < b.name)
				  return -1
				else
				  return 1;
			});
		}
	};

    var template = new erazor.Template(TEMPLATE);
#if php
    php.Lib.print(template.execute(h));
#elseif neko
    neko.Lib.print(template.execute(h));
#end
  }
}