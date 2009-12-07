/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

typedef PropertyObject = Dynamic;

class HTemplate 
{
	private var template : String;
	
	public function new(template : String)
	{
		this.template = template;
	}
	
	public function execute(content : PropertyObject) : String
	{
		return null;
	}
}