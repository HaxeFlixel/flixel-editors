package flixel.editors;
import flixel.addons.ui.FlxUI.NamedBool;
import flixel.util.FlxDestroyUtil;

/**
 * An extra bit of metadata for animation frames -- specifies the location of, e.g. spawnable
 * events/objects like when/where a punch lands, or when/where a bullet should happen
 * @author larsiusprime
 */
class AnimSweetSpot implements IFlxDestroyable
{
	public var x:Float;	//frame location associated with the sweet spot, if any
	public var y:Float;
	
	public var name:String;	//name associated with the sweet spot, if any
	
	public function new(name_:String="",x_:Float=-2,y_:Float=-1) 
	{
		name = name_;
		x = x_;
		y = y_;
	}
	
	public inline function copy():AnimSweetSpot
	{
		return new AnimSweetSpot(name, x, y);
	}
	
	public function toString():String
	{
		var str:String = "{name:" + name+", (" + x + "," + y + ")}";
		return str;
	}
	
	public function destroy():Void
	{
		x = 0;
		y = 0;
		name = "";
	}
}