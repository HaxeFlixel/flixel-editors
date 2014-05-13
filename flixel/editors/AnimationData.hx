package flixel.editors;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

/**
 * Stores Animation MetaData for an EntitySprite. 
 * Contains basic FlxSprite animation information, along with "sweet spots",
 * additional metadata that can be used to specify when something like a punch
 * or projectile should happen in an animation, and where it should appear.
 * @author larsiusprime
 */
class AnimationData implements IFlxDestroyable
{
	public var name:String = "";						//name of the animation, unique string identifier
	
	public var frames:Array<Int> = null;				//raw frame data
	public var sweets:Map<Int,AnimSweetSpot> = null;	//sweet spots in the animation, keyed by index
	
	public var frameRate:Int = 30;
	public var looped:Bool = false;
	
	public function new() 
	{
		frames = [];
	}
	
	public function destroy():Void {
		frames = null;
		if (sweets != null) 
		{
			for (key in sweets.keys()) 
			{
				sweets.remove(key);
			}
		}
		sweets = null;
	}
	
	/**
	 * Add a sweet spot at the given animation frame location
	 * @param	i		frame in the animation
	 * @param	Sweet	SweetSpot data
	 */
	
	public function setSweetSpot(i:Int, Sweet:AnimSweetSpot):Void {
		if (sweets == null) {
			sweets = new Map<Int, AnimSweetSpot>();
		}
		sweets.set(i, Sweet);
	}
	
	/**
	 * Modify an existing sweet spot, or create one if it doesn't exist
	 * @param	i		frame in the animation
	 * @param	Name	new name for the sweet spot
	 * @param	X		x location of sweet spot
	 * @param	Y		y location of sweet spot
	 */
	
	public function editSweetSpot(i:Int,Name:String,X:Float,Y:Float):Void {
		if (sweets == null) {
			sweets = new Map<Int,AnimSweetSpot>();
		}
		var s:AnimSweetSpot = sweets.get(i);
		if (s == null) {
			s = new AnimSweetSpot(Name, X, Y);
			sweets.set(i, s);
		}else {
			s.name = Name;
			s.x = X;
			s.y = Y;
		}
	}
	
	/**
	 * Remove a sweet spot from the animation
	 * @param	i	frame in the animation
	 */
	
	public function removeSweetSpot(i:Int):Void {
		if (sweets == null) {
			return;
		}else {
			if (sweets.exists(i)) {
				sweets.remove(i);
			}
		}
	}
	
	/**
	 * Returns whether a sweet spot exists at that location
	 * @param	i	frame in the animation
	 * @return
	 */
	
	public function hasSweetSpot(i:Int):Bool {
		if (sweets != null && sweets.exists(i)) {
			return true;
		}
		return false;
	}
	
	/**
	 * Returns a sweet spot at the given location
	 * @param	i	frame in the animation
	 * @return
	 */
	
	public function getSweetSpot(i:Int):AnimSweetSpot{
		if (sweets == null) {
			return null;
		}
		return sweets.get(i);
	}
	
}