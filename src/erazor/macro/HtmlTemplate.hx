package erazor.macro;

import erazor.Output;

@:abstractTemplate class HtmlTemplate extends Template
{
	
	override public function escape(str:String):String 
	{
		return StringTools.htmlEscape(str, true);
	}
	
	public function raw(str : Dynamic)
	{
		return new SafeString(Std.string(str));
	}
	
}