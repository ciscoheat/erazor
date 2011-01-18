package erazor;

class ScriptBuilder
{
	private var context : String;

	public function new(context : String)
	{
		this.context = context;
	}
	
	public function build(blocks : Array<TBlock>) : String
	{
		var buffer = new StringBuf();
		
		for(block in blocks)
		{
			buffer.add(blockToString(block));
		}
		return buffer.toString();
	}
	
	public function blockToString(block : TBlock) : String
	{
		switch(block)
		{
			case literal(s):
				return context + ".add('" + StringTools.replace(s, "'", "\\'") + "');\n";
			
			case codeBlock(s):
				return s + "\n";
			
			case printBlock(s):
				return context + ".add(" + s + ");\n";
		}
	}
}