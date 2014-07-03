package flixel.editors;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.editors.EntityGraphics.EntityColorLayer;
import flixel.editors.EntitySkin;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.geom.ColorTransform;
import flixel.addons.ui.U;
import flixel.animation.FlxAnimation;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.loaders.CachedGraphics;
import openfl.Assets;
import sys.FileSystem;
import sys.io.File;

/**
 * An extension of FlxSprite with some extra power -- namely extra metadata for animation,
 * and the ability to dynamically recolor the sprite.
 * @author larsiusprime
 */
class EntitySprite extends FlxSprite
{
	public var name:String;
	
	/**
	 * Callback for when a sweet-spot animation frame is played, parameters:
	 * AnimationName:String
	 * SweetSpotName:String
	 * X:Float
	 * Y:Float
	 */
	public var onSweetSpotCallback:String->String->Float->Float->Void;
	
	public function new(X:Float=0,Y:Float=0,G:EntityGraphics) 
	{
		super(X, Y);
		
		var s:EntitySkin = cast G.map_skins.get(G.skinName);
		if (s != null) {
			loadEntityGraphics(G);
		}
	}
	
	public function addAnimation(anim:AnimationData):Void {
		animation.add(anim.name, anim.frames, anim.frameRate, anim.looped);
		if (anim.sweets != null) {
			if (_sweetSpotMap == null) {
				_hasSweetSpots = true;
				_sweetSpotMap = new Map < String, Array<AnimSweetSpot> > ();
			}
			
			if (!_sweetSpotMap.exists(anim.name)) {
				_sweetSpotMap.set(anim.name, new Array<AnimSweetSpot>());
			}
			
			var arr:Array<AnimSweetSpot> = _sweetSpotMap.get(anim.name);
			for (ss in anim.sweets)
			{
				if (ss != null)
				{
					arr.push(ss.copy());
				}
				else
				{
					arr.push(null);
				}
			}
		}
	}

	public function loadEntityGraphics(G:EntityGraphics):Void {
		var s:EntitySkin = cast G.skin;
		
		if (G.skin.color_change_mode != EntityGraphics.COLOR_CHANGE_NONE)
		{
			loadCustomColors(G);
		}
		else 
		{
			if (G.remotePath == "") {
				loadGraphic(U.gfx(G.asset_src), true, s.width, s.height);
			}else {
				loadGraphic(BitmapData.load(G.remotePath + G.asset_src), true, s.width, s.height);
			}
		}
		
		offset.x = G.skin.off_x;
		offset.y = G.skin.off_y;
		
		loadAnimations(G.animations);
	}
	
	public function loadCustomColors(G:EntityGraphics):Void {
		
		//Get the unique key for this colorized sprite permutation
		var customColorKey:String = G.colorKey;
		
		//See if it already exists and if so return early
		if (FlxG.bitmap.checkCache(customColorKey)) 
		{
			loadGraphic(customColorKey, true, G.skin.width, G.skin.height);
			return;
		}
		
		//Else, construct it from scratch using the proper method and cache it
		if (G.skin.color_change_mode == EntityGraphics.COLOR_CHANGE_LAYERS) 
		{
			loadCustomColorLayers(G);	//colorize layers and composite them -- "HD style" sprites
		}
		else if (G.skin.color_change_mode == EntityGraphics.COLOR_CHANGE_PIXEL_PALETTE) 
		{
			loadCustomPixelPalette(G);	//do individual per-pixel exact-color-value palette swaps
		}
	}
	
	public function loadAnimations(Anims:Map<String,AnimationData>, destroyOld:Bool=true):Void {
		if (destroyOld) {
			animation.destroyAnimations();
		}
		for (key in Anims.keys()) {
			addAnimation(Anims.get(key));
		}
		animation.callback = animationCallback;
	}
	
	/**
	 * Returns the list of AnimSweetSpot metadata for the given animation (assumes current if no parameter)
	 * @param	animationName
	 * @return
	 */
	
	public function getSweetSpotList(?animationName:String):Array<AnimSweetSpot>
	{
		if (animationName == null)
		{
			if (animation != null && animation.curAnim != null)
			{
				animationName = animation.curAnim.name;
			}
		}
		if (animationName == null)
		{
			return null;
		}
		if (!_sweetSpotMap.exists(animationName))
		{
			return null;
		}
		return _sweetSpotMap.get(animationName);
	}
	
	/**
	 * Returns a specific AnimSweetSpot metadata for a specific animation
	 * @param	animationName
	 * @param	frame
	 * @param	sweetSpotName
	 * @return
	 */
	
	public function getSweetSpot(?animationName:String, ?frame:Int, ?sweetSpotName:String):AnimSweetSpot
	{
		var list = getSweetSpotList(animationName);
		if (list != null)
		{
			if (frame != null && list.length > frame)
			{
				return list[frame];
			}
			if (sweetSpotName != null)
			{
				var ss:AnimSweetSpot;
				for (ss in list)
				{
					if (ss.name == sweetSpotName)
					{
						return ss;
					}
				}
			}
		}
		return null;
	}
	
	/**PRIVATE**/
	
	private var _hasSweetSpots:Bool = false;
	private var _sweetSpotMap:Map<String,Array<AnimSweetSpot>> = null;
	
	/**
	 * Callback for animation stuffs
	 * @param	Name			Name of the animation
	 * @param	AnimFrame		Index of the frame in the current animation
	 * @param	SpriteFrame		Index of the frame in the Sprite Sheet
	 */
	
	private function animationCallback(Name:String,AnimFrame:Int,SpriteFrame:Int):Void {
		if (_hasSweetSpots && _sweetSpotMap.exists(Name)) 				//If we have at least one sweet spot for this animation
		{
			if (onSweetSpotCallback != null)
			{
				var arr:Array<AnimSweetSpot> = _sweetSpotMap.get(Name);		//Get the list of sweet spots
				if (AnimFrame < arr.length) 
				{
					if (arr[AnimFrame] != null) 							//If the current frame has a sweet spot
					{
						var sweet:AnimSweetSpot = arr[AnimFrame];
						onSweetSpotCallback(Name,sweet.name,sweet.x,sweet.y);	//do the sweet spot callback
					}
				}
			}
		}
	}
	
	private function loadCustomPixelPalette(G:EntityGraphics):Void 
	{
		//Get the base layer
		
		var baseLayer:BitmapData = null;
		if (G.remotePath == "") {
			baseLayer = Assets.getBitmapData(U.gfx(G.asset_src));
		}else {
			#if sys
				var daPath:String = G.remotePath + G.asset_src + ".png";
				if (FileSystem.exists(daPath))
				{
					baseLayer = BitmapData.load(daPath);
				}
			#end
		}
		
		var baseCopy = baseLayer.clone();
		
		baseLayer = null;
		
		var orig_color:FlxColor;
		var pix_color:FlxColor;
		var replace_color:FlxColor;
		
		var i:Int = 0;
		
		//Strip off the palette data in the image
		for (i in 0...G.skin.list_original_pixel_colors.length) 
		{
			orig_color = G.skin.list_original_pixel_colors[i];
			pix_color = baseCopy.getPixel32(0, i);
			if (pix_color == orig_color) 
			{
				baseCopy.setPixel32(0, i, 0x00000000);
			}
		}
		
		if (G.skin.list_colors != null)
		{
			//Loop through color replacement rules and apply them pixel for pixel
			for (i in 0...G.skin.list_original_pixel_colors.length) 
			{
				if (i < G.skin.list_colors.length) 
				{
					orig_color = G.skin.list_original_pixel_colors[i];
					replace_color = G.skin.list_colors[i];
					var ignored:Bool = false;
					if (G.ignoreColor != null) {
						var testColor:FlxColor = replace_color | 0x00FFFFFF;
						if ((replace_color & 0x00FFFFFF) == G.ignoreColor) {
							ignored = true;
						}
					}
					if (!ignored && replace_color != 0x00000000) 
					{
						try {
							baseCopy.threshold(baseCopy, baseCopy.rect, _flashPointZero, "==", orig_color, replace_color);
						}catch (msg:Dynamic) {
							FlxG.log.error(msg);
						}
					}
				}
			}
		}
		
		//Load the base copy into our graphic and cache it with our custom color key
		loadGraphic(baseCopy, true, G.skin.width, G.skin.height, false, G.colorKey);
	}
	
	private function loadCustomColorLayers(G:EntityGraphics):Void{
		//Get the base layer
		var baseLayer:BitmapData = null;
		
		if(G.remotePath == ""){
			baseLayer = Assets.getBitmapData(U.gfx(G.asset_src));
		}else {
			#if sys
				baseLayer = BitmapData.load(G.remotePath + G.asset_src + ".png");
			#end
		}
		
		//Clone pixels so we don't overwrite the original bitmap data
		var baseCopy = baseLayer.clone();
		
		baseLayer = null;
		
		//Load the base copy into our graphic and cache it with our custom color key
		loadGraphic(baseCopy, true, G.skin.width, G.skin.height, false, G.colorKey);
		
		if (G.skin.list_colors != null)
		{
			var i:Int = 0;
			
			//Loop through color layers, colorize and stamp them onto the graphic
			for (layer in G.skin.list_color_layers) 
			{
				//Grab a piece
				var piece:FlxSprite = new FlxSprite();
				if (G.remotePath == "")
				{
					piece.loadGraphic(U.gfx(G.skin.path + "/" + layer.asset_src));
				}else 
				{
					var pieceBmp:BitmapData = BitmapData.load(G.remotePath + G.skin.path + "/" + layer.asset_src + ".png");
					piece.loadGraphic(pieceBmp);
				}
				
				//Grab the color from the skin
				if(G.skin.list_colors.length > i){
					piece.color = G.skin.list_colors[i];
				}
				
				//Stamp it on the base
				stamp(piece);
				
				//destroy piece
				piece.destroy();
				piece = null;
				
				i++;
			}
		}
	}
}