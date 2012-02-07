package erazor.macro;

/**
 * ...
 * @author Waneck
 */

@:autoBuild(erazor.macro.Build.buildTemplate())
class Template<T>
{
	public function new()
	{

	}

#if display
	public function execute(context:T):String
	{
		return null;
	}
#end
}