package erazor.error;

/**
 * ...
 * @author Waneck
 */

class ParserError
{
	public var msg(default, null):String;
	public var pos(default, null):Int;
	public var excerpt(default, null):String;
	
	public function new(msg, pos, ?excerpt)
	{
		this.msg = msg;
		this.pos = pos;
		this.excerpt = excerpt;
	}
	
	public function toString()
	{
		var excerpt = this.excerpt;
		if (excerpt != null)
		{
			var nl = excerpt.indexOf("\n");
			if (nl != -1)
				excerpt = excerpt.substr(0, nl);
		}
		
		return msg + " @ " + pos + (excerpt != null ? (" ( \"" + excerpt + "\" )") : "");
	}
}