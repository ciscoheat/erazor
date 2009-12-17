class Main
{
  static var TEMPLATE =
"{eval}
  ucwords = function(s) {
    var r = '';
    var arr = s.split(' ');
    for (v in arr)
      r += v.substr(0, 1).toUpperCase() + v.substr(1, null) + ' ';
    return r;
  };

  list.sort(function(a, b) {
    if (a.name == b.name)
      return 0;
    else if (a.name < b.name)
      return -1
    else
      1;
  });
{end}
{set line}{:repeat('=', title.length)}{end}

{: line}
{: ucwords(title)}
{: line }

{: content.substr(0, 40)}...

{for item in list}
  * {if(item.sex == 'f')}Ms.{else}Mr.{end} {: item.name}
{end}

";
  static function main()
  {
    var h = new Hash<Dynamic>();
    h.set('title', 'htemplate - the template system for haxe');
    h.set('content', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In ullamcorper felis non libero blandit facilisis. In hac habitasse platea dictumst');
    h.set('list', [
      { sex : 'm', name : 'Boris' },
      { sex : 'f', name : 'Doris' },
      { sex : 'm', name : 'John' },
      { sex : 'f', name : 'Jane' },
    ]);
    h.set('repeat', function(v, l) {
      return StringTools.lpad('', v, l);
    });

    var template = new htemplate.Template(TEMPLATE);
    trace(template.execute(h));
  }
}