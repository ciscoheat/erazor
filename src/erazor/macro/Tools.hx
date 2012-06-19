package erazor.macro;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
 * Some Tools to 
 * @author waneck
 */

class Tools 
{

	@:macro public static function setData(template:ExprOf<Template>, fields:Array<Expr>):Expr
	{
		var bl = [];
		//var template = fields.shift();
		//if (template == null) throw new Error("setData must contain at least the template variable", Context.currentPos())
		
		var templateVar = null;
		
		switch(template.expr)
		{
			case EConst(c): //CIdent
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