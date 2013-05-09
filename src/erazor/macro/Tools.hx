package erazor.macro;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Some Tools to make it easier to work with Macro Templates
 * @author waneck
 */

class Tools 
{
	/**
	 * Allows to set data for the template with the following syntax:
	 * 
	 * 		using Tools;
	 * 		var template = new MyTemplate().setData(a = "a", b = "b", c = "c");
	 * 
	 * @param	template	the Template on which we are going to set the data
	 * @param	fields		rest parameters of the fields to be set. They must follow the convention: field = (value)
	 * @return	An expression block that sets all the values and has the template var as the last expression.
	 */
#if haxe_210
	macro public static function setData(template:ExprOf<Template>, fields:Array<Expr>):Expr
#else
	macro public static function setData(fields:Array<Expr>):Expr
#end
	{
		var bl = [];
#if !haxe_210
		var template = fields.shift();
		if (template == null) throw new Error("setData must contain at least the template variable", Context.currentPos());
#end
		
		var templateVar = null;
		
		switch(template.expr)
		{
			case EConst(_): //CIdent
				templateVar = template;
			default:
				bl.push( { expr : EVars([ { type: null, name : "__tmpl__", expr : template } ]), pos : template.pos } );
				templateVar = { expr: EConst(CIdent("__tmpl__")), pos: template.pos };
		}
		
		for (f in fields)
		{
			switch(f.expr)
			{
				case EBinop(op, e1, e2):
					switch(op)
					{
						case OpAssign:
							bl.push( 
							{
								expr : EBinop(OpAssign, { expr: EField(templateVar, Build.getString(e1, true)), pos : e1.pos }, e2),
								pos : f.pos
							});
							continue;
						default:
					}
				default:
			}
			throw new Error("Invalid setData expression: Only 'field = value' is accepted.", f.pos);
		}
		
		bl.push(templateVar);
		return { expr : EBlock(bl), pos : Context.currentPos() };
	}
	
}