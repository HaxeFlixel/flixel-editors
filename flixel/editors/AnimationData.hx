package flixel.editors;
import flixel.FlxSprite;
import flixel.addons.ui.U;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
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
	public var sweets:Array<AnimSweetSpot> = null;		//sweet spots in the animation, keyed by index
	
	public var frameRate:Int = 30;
	public var looped:Bool = false;
	
	public var flipX:Bool = false;
	public var flipY:Bool = false;
	
	public function new() 
	{
		frames = [];
	}
	
	public function copy():AnimationData
	{
		var ad = new AnimationData();
		ad.name = name;
		
		ad.frames = null;
		if (frames != null) ad.frames = U.copy_shallow_arr_i(frames);
		
		ad.sweets = null;
		if (sweets != null) 
		{
			ad.sweets = [];
			for (sweet in sweets){
				var newSweet = (sweet != null ? sweet.copy() : null);
				ad.sweets.push(newSweet);
			}
		}
		
		ad.frameRate = frameRate;
		ad.looped = looped;
		ad.flipX = flipX;
		ad.flipY = flipY;
		
		return ad;
	}
	
	public function destroy():Void
	{
		FlxDestroyUtil.destroyArray(sweets);
		sweets = null;
	}
	
	/**
	 * Add a sweet spot at the given animation frame location
	 * @param	i		frame in the animation
	 * @param	Sweet	SweetSpot data
	 */
	
	public function setSweetSpot(i:Int, Sweet:AnimSweetSpot):Void {
		if (sweets == null)
		{
			sweets = [];
		}
		sweets[i] = Sweet;
	}
	
	/**
	 * Modify an existing sweet spot, or create one if it doesn't exist
	 * @param	i		frame in the animation
	 * @param	Name	new name for the sweet spot
	 * @param	X		x location of sweet spot
	 * @param	Y		y location of sweet spot
	 */
	
	public function editSweetSpot(i:Int,Name:String,X:Float,Y:Float):Void {
		if (sweets == null)
		{
			sweets = [];
		}
		
		var s:AnimSweetSpot = (sweets.length > i) ? sweets[i] : null;
		
		if (s == null)
		{
			s = new AnimSweetSpot(Name, X, Y);
			sweets[i] = s;
		}
		else
		{
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
		if (sweets == null)
		{
			return;
		}
		else
		{
			if (sweets.length > i)
			{
				sweets.splice(i, 1);
			}
		}
	}
	
	/**
	 * Returns whether a sweet spot exists at that location
	 * @param	i	frame in the animation
	 * @return
	 */
	
	public function hasSweetSpot(i:Int):Bool {
		if (sweets != null && sweets.length > i && sweets[i] != null)
		{
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
		if (sweets == null || sweets.length <= i)
		{
			return null;
		}
		return sweets[i];
	}
}