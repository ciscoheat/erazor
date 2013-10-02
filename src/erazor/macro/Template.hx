package erazor.macro;

/**
 * This is the macro Template class. In order to have a Template executed, you should extend it and add either
 * 
 * @:template("inline template here @someVar")
 *  or 
 * @:includeTemplate("path/to/template")
 * 
 * @author Waneck
 */

@:autoBuild(erazor.macro.Build.buildTemplate())
class Template
{
	public function new()
	{
		
	}
	
	public dynamic function escape(str : String) : String
	{
		return str;
	}
	
	public function execute():String
	{
		return null;
	}
}