package erazor;
import erazor.Template.PropertyObject;
import erazor.Output;

class HtmlTemplate extends Template
{

	public function new(template : String) 
	{
		super(template);
		super.addHelper("raw", raw);
	}
	
	override public function escape(str : String) : String 
	{
		return StringTools.htmlEscape(str, true);
	}
	
	private static function raw(str : Dynamic)
	{
		return new SafeString(Std.string(str));
	}
	
}