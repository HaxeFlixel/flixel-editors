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
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.Assets;
import openfl.geom.Matrix;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.Lib;

/**
 * An extension of FlxSprite with some extra power -- namely extra metadata for animation,
 * and the ability to dynamically recolor the sprite.
 * @author larsiusprime
 */
class EntitySprite extends FlxSprite
{
	public var name:String;
	public var recycled:Bool = false;
	
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
		
		if (G != null)
		{
			var s:EntitySkin = cast G.map_skins.get(G.skinName);
			if (s != null)
			{
				loadEntityGraphics(G);
			}
		}
	}
	
	public function addAnimation(anim:AnimationData, fromAtlas:Bool=false):Void
	{
		if (!fromAtlas) {
			
			animation.add(anim.name, anim.frames, anim.frameRate, anim.looped);
			
		}
		else {
			
			addAtlasAnimation(this, anim);
			
		}
		
		if (anim.sweets != null)
		{
			_hasSweetSpots = true;
			
			if (_sweetSpotMap == null)
			{
				_sweetSpotMap = new Map < String, Array<AnimSweetSpot> > ();
			}
			
			if (!_sweetSpotMap.exists(anim.name))
			{
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
	
	public function loadEntityGraphics(G:EntityGraphics):Void
	{
		var hasScale:Bool = (G.scaleX != 1.0 || G.scaleY != 1.0);
		var skipLoad:Bool = false;
		var key = G.scaledColorKey;
		
		var isStack = G.skin.color_change_mode == EntityGraphics.COLOR_CHANGE_LAYERS_STACKED;
		
		var existScale = false;
		var hasAtlas = checkHasAtlas(G.skin.path, G.skin.asset_meta);
		
		_usingAtlas = hasAtlas;
		
		var skey:String = "";
		
		if (!hasAtlas)		//only check for software scaling if we're not doing atlases
		{
			if (isStack && hasScale)
			{
				skey = U.gfx(G.skin.path + "/" + G.skin.asset_src) + G.getScaleSuffix();
				existScale = FlxG.bitmap.checkCache(skey);
			}
			else if(hasScale)
			{
				existScale = FlxG.bitmap.checkCache(G.scaledColorKey);
			}
		}
		
		//We don't need to load it if we have a cached scale key
		if (existScale)
		{
			skipLoad = true;
			var frameWidth:Int = Math.round(G.skin.width * G.scaleX);
			var frameHeight:Int = Math.round(G.skin.height * G.scaleY);
			
			if (skey != "") key = skey;
			
			//Fixes a bug on where callbacks get called on recycle but not on construction
			animation.callback = null;
			
			loadGraphic(key, true, frameWidth, frameHeight);
			
			//If it's a sprite stack
			if (isStack && G.skin.list_color_layers != null)
			{
				//initialize layers
				_layerSprites = new FlxSpriteGroup();
				_layerSpriteProperties = [];
				
				for (i in 0...G.skin.list_color_layers.length)
				{
					if (G.skin.list_color_layers[i].asset_src != "")
					{
						var lf:FlxSprite = new FlxSprite(0, 0);
						skey = U.gfx(G.skin.path + "/" + G.skin.list_color_layers[i].asset_src) + G.getScaleSuffix();
						if (FlxG.bitmap.checkCache(skey))
						{
							lf.loadGraphic(skey, true, frameWidth, frameHeight);
						}
						
						_layerSprites.add(lf);
						_layerSpriteProperties.push({color:G.skin.list_colors[i],alpha:1,blend:BlendMode.NORMAL});
					}
				}
			}
			
			color = 0xFFFFFF;
		}
		
		if (!skipLoad)
		{
			basicLoad(G);
		}
		
		offset.set(0, 0);
		
		if (hasAtlas)
		{
			updateHitbox();
		}
		
		offset.x += Std.int(G.skin.off_x * G.scaleX);
		offset.y += Std.int(G.skin.off_y * G.scaleY);
		
		if (hasScale && !skipLoad && !hasAtlas)
		{
			if (G.skin != null)
			{
				doScale(G);
			}
			else
			{
				throw "Can't load if EntityGraphics.skin == null!";
			}
		}
		
		loadAnimations(G.animations, true, hasAtlas);
	}
	
	private function addAtlasAnimation(sprite:FlxSprite, anim:AnimationData):Void
	{
		var fNames = [];
		for (i in 0...anim.frames.length)
		{
			fNames.push(Std.string(anim.frames[i]));
		}
		sprite.animation.addByNames(anim.name, fNames, anim.frameRate, anim.looped);
	}
	
	private function checkHasAtlas(path:String, file:String, useAssets:Bool=true):Bool
	{
		var sys = false;
		#if sys
			sys = true;
		#end
		if (file == null || file == "") return false;
		if (file.indexOf(".xml") == -1) return false;
		if(!sys || useAssets) {
			if (!Assets.exists("assets/gfx/" + path + "/" + file)) {
				return false;
			}
		}
		else {
			#if sys
			if (FileSystem.exists("assets/gfx/" + path + "/" + file)) {
				return false;
			}
			#end
		}
		return true;
	}
	
	private function getBmp(file:String, remotePath:String=""):BitmapData
	{
		if (remotePath == "" || remotePath == null)
		{
			var daPath = U.gfx(file);
			if (Assets.exists(daPath, AssetType.IMAGE))
			{
				return Assets.getBitmapData(daPath);
			}
		}
		else
		{
			var daPath = remotePath + file + ".png";
			#if sys
				if (FileSystem.exists(daPath))
				{
					#if (lime_legacy || hybrid)
						return BitmapData.load(daPath);
					#else
						return BitmapData.fromFile(daPath);
					#end
				}
			#else
				if (Assets.exists(daPath))
				{
					return Assets.getBitmapData(daPath);
				}
			#end
		}
		return null;
	}
	
	private function getAtlasXmlStr(path:String, file:String, useAssets:Bool=true):String
	{
		var sys = false;
		#if sys
			sys = true;
		#end
		if (!checkHasAtlas(path, file, useAssets)) return "";
		
		if(!sys || useAssets) {
			return Assets.getText("assets/gfx/" + path + "/" + file);
		}
		else {
			#if sys
				return File.getContent("assets/gfx/" + path + "/" + file);
			#end
		}
		
		return "";
	}
	
	private function loadAtlasFrames(sprite:FlxSprite, gfx:EntityGraphics, asset_src:String, xmlStr:String):Void
	{
		var skin = gfx.skin;
		var imgSrc = U.gfx(skin.path + "/" + asset_src);
		
		var tex = FlxAtlasFrames.fromSparrow(imgSrc, xmlStr);
		sprite.frames = tex;
		
		sprite.scale.set(gfx.scaleX, gfx.scaleY);
		sprite.width = Std.int(gfx.scaleX * gfx.skin.width); // sprite.frameWidth;
		sprite.height = Std.int(gfx.scaleY * gfx.skin.height); // sprite.frameHeight;
		sprite.updateHitbox();
	}
	
	private function basicLoad(G:EntityGraphics):Void
	{
		var s:EntitySkin = cast G.skin;
		
		if (G.skin.color_change_mode != EntityGraphics.COLOR_CHANGE_NONE)
		{
			loadCustomColors(G);
		}
		else 
		{
			var xmlStr = getAtlasXmlStr(G.skin.path, G.skin.asset_meta);
			if (xmlStr != "")
			{
				loadAtlasFrames(this, G, s.asset_src, xmlStr);
			}
			else
			{
				loadGraphic(getBmp(s.path + "/" + s.asset_src, G.remotePath), true, s.width, s.height);
			}
		}
	}
	
	private function doScale(G:EntityGraphics):Void
	{
		var s:EntitySkin = G.skin;
		var fWidth:Int = Math.round(s.width*G.scaleX);
		var fHeight:Int = Math.round(s.height*G.scaleY);
		var framesWide:Int = Std.int(pixels.width / s.width);
		var framesTall:Int = Std.int(pixels.height / s.height);
		var newWidth:Int = fWidth * framesWide;
		var newHeight:Int = fHeight * framesTall;
		
		var scaleKey:String = G.scaledColorKey;
		
		var isStack:Bool = G.skin.color_change_mode == EntityGraphics.COLOR_CHANGE_LAYERS_STACKED;
		
		//TODO: if there's issues with off-by-one factors in frame boundaries due to scaling, perhaps use UU.scaleTileBMP instead
		
		//If a cached version of base layer exists
		if(FlxG.bitmap.checkCache(scaleKey) == true)
		{
			//Load it
			loadGraphic(scaleKey, true, fWidth, fHeight);
			
			//If it's a sprite stack...
			if (isStack)
			{
				//Reload each of the layers too
				for (i in 0..._layerSprites.members.length)
				{
					var lkey = _layerSprites.members[i].graphic.key + G.getScaleSuffix();
					var lgfx = FlxG.bitmap.get(lkey);
					_layerSprites.members[i].loadGraphic(lgfx, true, fWidth, fHeight);
				}
			}
		}
		else
		{
			
			//Scale to appropriate size
			var scaledPixels:BitmapData = new BitmapData(newWidth, newHeight,true,0x00000000);
			var matrix:Matrix = new Matrix();
			matrix.scale(newWidth / pixels.width, newHeight / pixels.height);
			
			scaledPixels.draw(pixels, matrix, null, null, null, G.scaleSmooth);
			
			//Load resulting image
			loadGraphic(scaledPixels, true, fWidth, fHeight, false, scaleKey);
			
			//If it's a sprite stack...
			if (isStack && _layerSprites != null)
			{
				//Scale the various layers
				for (i in 0..._layerSprites.members.length)
				{
					
					scaledPixels = new BitmapData(newWidth, newHeight, true, 0x00000000);
					scaledPixels.draw(_layerSprites.members[i].graphic.bitmap, matrix, null, null, null, G.scaleSmooth);
					
					var sgfx:FlxGraphic = null;
					
					var skey:String = _layerSprites.members[i].graphic.key + G.getScaleSuffix();
					sgfx = FlxG.bitmap.add(scaledPixels, false, skey);
					_layerSprites.members[i].loadGraphic(sgfx, true, fWidth, fHeight);
				}
			}
		}
	}
	
	public function loadCustomColors(G:EntityGraphics):Void {
		
		if (_layerSprites != null)
		{
			_layerSprites.destroy();
			_layerSprites = null;
		}
		
		//Get the unique key for this colorized sprite permutation
		var customColorKey:String = G.colorKey;
		
		var hasAtlas = checkHasAtlas(G.skin.path, G.skin.asset_meta);
		
		//If not an atlas, see if it already exists and if so return early
		if (!hasAtlas)
		{
			if(G.skin.color_change_mode != EntityGraphics.COLOR_CHANGE_LAYERS_STACKED && FlxG.bitmap.checkCache(customColorKey)) 
			{
				loadGraphic(customColorKey, true, G.skin.width, G.skin.height);
				return;
			}
		}
		
		//Else, construct it from scratch using the proper method
		if (G.skin.color_change_mode == EntityGraphics.COLOR_CHANGE_LAYERS_BAKED) 
		{
			loadCustomColorLayersBaked(G);	//colorize layers and composite them -- "HD style" sprites
		}
		else if (G.skin.color_change_mode == EntityGraphics.COLOR_CHANGE_LAYERS_STACKED) 
		{
			loadCustomColorLayersStacked(G); //colorize layers and stack them -- "HD style" sprites
		}
		else if (G.skin.color_change_mode == EntityGraphics.COLOR_CHANGE_PIXEL_PALETTE) 
		{
			loadCustomPixelPalette(G);	//do individual per-pixel exact-color-value palette swaps
		}
		
		if (G.skin.color_change_mode != EntityGraphics.COLOR_CHANGE_LAYERS_STACKED)
		{
			if (FlxG.bitmap.checkCache(customColorKey) == false)
			{
				FlxG.bitmap.add(pixels, false, customColorKey);
			}
		}
	}
	
	public function loadAnimations(Anims:Map<String,AnimationData>, destroyOld:Bool = true, fromAtlas:Bool = false):Void
	{
		if (destroyOld)
		{
			animation.destroyAnimations();
		}
		if (_sweetSpotMap != null)
		{
			for (key in _sweetSpotMap.keys())
			{
				var arr = _sweetSpotMap.get(key);
				FlxDestroyUtil.destroyArray(arr);
				_sweetSpotMap.remove(key);
			}
		}
		for (key in Anims.keys())
		{
			addAnimation(Anims.get(key), fromAtlas);
		}
		animation.callback = animationCallback;
		
		if (_layerSprites != null)
		{
			for (i in 0..._layerSprites.members.length)
			{
				if (destroyOld)
				{
					_layerSprites.members[i].animation.destroyAnimations();
				}
				for (key in Anims.keys())
				{
					addAtlasAnimation(_layerSprites.members[i], Anims.get(key));
				}
			}
		}
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
		if (_sweetSpotMap == null || !_sweetSpotMap.exists(animationName))
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
	
	public override function destroy():Void
	{
		super.destroy();
		if (_layerSprites != null)
		{
			_layerSprites.destroy();
		}
		_layerSprites = null;
	}
	
	override function updateMotion(elapsed:Float):Void 
	{
		super.updateMotion(elapsed);
		if (_layerSprites != null)
		{
			_layerSprites.x = x;
			_layerSprites.y = y;
			_layerSprites.offset.set(offset.x, offset.y);
			_layerSprites.updateMotion(elapsed);
		}
	}
	
	override function updateAnimation(elapsed:Float):Void 
	{
		super.updateAnimation(elapsed);
		if (_layerSprites != null)
		{
			for (i in 0..._layerSprites.members.length)
			{
				_layerSprites.members[i].updateAnimation(elapsed);
				if (animation.curAnim != null && _layerSprites.members[i].animation.curAnim == null)
				{
					_layerSprites.members[i].animation.play(animation.curAnim.name, true, false, animation.curAnim.curFrame);
				}
			}
		}
	}
	
	override public function draw():Void
	{
		super.draw();
		if (_layerSprites != null)
		{
			for (i in 0..._layerSprites.members.length)
			{
				_layerSprites.members[i].animation.frameIndex = animation.frameIndex;
				_layerSprites.members[i].draw();
			}
		}
	}
	
	public override function set_flipX(Value:Bool):Bool
	{
		Value = super.set_flipX(Value);
		if (_layerSprites != null)
		{
			_layerSprites.flipX = Value;
		}
		return Value;
	}
	
	public override function set_flipY(Value:Bool):Bool
	{
		Value = super.set_flipY(Value);
		if (_layerSprites != null)
		{
			_layerSprites.flipY = Value;
		}
		return Value;
	}
	
	public override function set_alpha(Alpha:Float):Float
	{
		Alpha = super.set_alpha(Alpha);
		if (_layerSprites != null)
		{
			for (i in 0..._layerSpriteProperties.length)
			{
				var layerAlpha = _layerSpriteProperties[i].alpha;
				layerAlpha *= Alpha;
				_layerSprites.members[i].alpha = layerAlpha;
			}
		}
		return Alpha;
	}
	
	public override function set_blend(Blend:BlendMode):BlendMode
	{
		super.set_blend(Blend);
		if (_layerSprites != null)
		{
			_layerSprites.blend = Blend;
		}
		return Blend;
	}
	
	public override function set_color(Color:FlxColor):FlxColor
	{
		super.set_color(Color);
		if (_layerSprites != null)
		{
			var c_r:Float = Color.redFloat;
			var c_g:Float = Color.greenFloat;
			var c_b:Float = Color.blueFloat;
			for (i in 0..._layerSpriteProperties.length)
			{
				var layerColor:FlxColor = _layerSpriteProperties[i].color;
				layerColor.redFloat *= c_r;
				layerColor.greenFloat *= c_g;
				layerColor.blueFloat *= c_b;
				_layerSprites.members[i].color = layerColor;
			}
		}
		return Color;
	}
	
	/**PRIVATE**/
	
	private var _dirtyAnim:String = "";
	
	private var _usingAtlas:Bool = false;
	private var _hasSweetSpots:Bool = false;
	private var _sweetSpotMap:Map<String,Array<AnimSweetSpot>> = null;
	
	private var _layerSprites:FlxSpriteGroup;
	private var _layerSpriteProperties:Array<LayerSpriteProperty>;
	
	private var _lastAnimFrame:Int = 0;
	private var _lastAnimName:String = "";
	
	/**
	 * Callback for animation stuffs
	 * @param	Name			Name of the animation
	 * @param	AnimFrame		Index of the frame in the current animation
	 * @param	SpriteFrame		Index of the frameR in the Sprite Sheet
	 */
	
	private function animationCallback(Name:String, AnimFrame:Int, SpriteFrame:Int):Void
	{
		if (_hasSweetSpots && _sweetSpotMap.exists(Name)) 				//If we have at least one sweet spot for this animation
		{
			if (onSweetSpotCallback != null && (AnimFrame != _lastAnimFrame || Name != _lastAnimName))
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
		
		if (animation.finished)
		{
			onAnimationFinish(Name);
		}
		
		_lastAnimFrame = AnimFrame;
		_lastAnimName  = Name;
	}
	
	private function onAnimationFinish(Name:String):Void
	{
		//override per subclass
	}
	
	private function loadCustomPixelPalette(G:EntityGraphics):Void 
	{
		//Get the base layer
		
		var baseLayer:BitmapData = getBmp(G.asset_src,G.remotePath);
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
	
	private function loadCustomColorLayersStacked(G:EntityGraphics):Void
	{
		//Load the base layer first
		
		var baseKey:String = G.skin.path + "/" + G.asset_src + ".png";
		
		var xmlStr = getAtlasXmlStr(G.skin.path, G.skin.asset_meta);
		var hasAtlas = (xmlStr != "");
		
		if (hasAtlas)
		{
			loadAtlasFrames(this, G, G.skin.asset_src, xmlStr);
		}
		else
		{
			loadGraphic(getBmp(G.skin.asset_src, G.remotePath), true, G.skin.width, G.skin.height, false, baseKey);
		}
		
		//Then load each of the other layers
		
		var t:ColorTransform = null;
		var zpt:Point = new Point();
		
		if (G != null && G.skin != null && G.skin.list_colors != null && G.skin.list_color_layers != null)
		{
			var i:Int = 0;
			
			//Loop through color layers, colorize them, and add them as layers
			for (layer in G.skin.list_color_layers) 
			{
				if (_layerSprites == null)
				{
					_layerSprites = new FlxSpriteGroup();
					_layerSpriteProperties = [];
				}
				
				//Grab a piece
				if (layer.asset_src != null && layer.asset_src != "")
				{
					var piece:BitmapData = null;
					var exists:Bool = false;
					
					var gskinpath:String = G.skin.path + "/" + layer.asset_src + ".png";
					
					var layerXmlStr = getAtlasXmlStr(G.skin.path, layer.asset_meta);
					var layerHasAtlas = (xmlStr != "");
					
					if (!layerHasAtlas && FlxG.bitmap.checkCache(gskinpath))
					{
						piece = FlxG.bitmap.get(gskinpath).bitmap;
						exists = true;
					}
					else
					{
						piece = getBmp(gskinpath, G.remotePath);
					}
					
					if (piece != null)
					{
						var c:FlxColor = FlxColor.WHITE;
						if (G.skin.list_colors.length > i)
						{
							c = G.skin.list_colors[i];
						}
						
						var fs = new FlxSprite();
						
						if (!hasAtlas)
						{
							var lkey = U.gfx(G.skin.path + "/" + layer.asset_src + ".png");
							var lgfx:FlxGraphic = null;
							if (FlxG.bitmap.checkCache(lkey) == false)
							{
								lgfx = FlxG.bitmap.add(piece, false, lkey);
							}
							loadGraphic(lgfx, true, frameWidth, frameHeight);
						}
						else
						{
							loadAtlasFrames(fs, G, layer.asset_src, layerXmlStr);
						}
						
						_layerSprites.add(fs);
						_layerSpriteProperties.push({color:c,alpha:1.0,blend:BlendMode.NORMAL});
					}
				}
				
				color = 0xFFFFFF;
				
				i++;
			}
		}
	}
	
	private function loadCustomColorLayersBaked(G:EntityGraphics):Void
	{
		//Get the base layer
		var baseLayer:BitmapData = getBmp(G.asset_src, G.remotePath);
		
		//Clone pixels so we don't overwrite the original bitmap data
		var baseCopy = baseLayer.clone();
		
		baseLayer = null;
		
		//Load the base copy into our graphic and cache it with our custom color key
		loadGraphic(baseCopy, true, G.skin.width, G.skin.height, false, G.colorKey);
		
		var t:ColorTransform = null;
		var zpt:Point = new Point();
		
		if (G != null && G.skin != null && G.skin.list_colors != null && G.skin.list_color_layers != null)
		{
			var i:Int = 0;
			
			//Loop through color layers, colorize and stamp them onto the graphic
			for (layer in G.skin.list_color_layers) 
			{
				//Grab a piece
				
				if (layer.asset_src != null && layer.asset_src != "")
				{
					var piece:BitmapData = getBmp(G.skin.path + "/" + layer.asset_src, G.remotePath);
					
					if (piece != null)
					{
						var trans:ColorTransform = null;
						
						//Grab the color from the skin
						
						if (G.skin.list_colors.length > i)
						{
							var c:FlxColor = G.skin.list_colors[i];
							if (t == null)
							{
								t = new ColorTransform(1.0, 1.0, 1.0, 1.0, 0, 0, 0, 0);
							}
							t.redMultiplier = c.redFloat;
							t.greenMultiplier = c.greenFloat;
							t.blueMultiplier = c.blueFloat;
							trans = t;
						}
						
						if (trans != null)
						{
							//manual clone b/c it was crashing for some reason:
							piece.colorTransform(piece.rect, trans);
						}
						
						//Stamp it on the base
						pixels.copyPixels(piece, piece.rect, zpt, null, null, true);
						
						//destroy piece
						piece.dispose();
						piece = null;
					}
				}
				
				dirty = true;
				calcFrame();
				
				i++;
			}
		}
	}
	
	private function safeColorTransform(piece:BitmapData, trans:ColorTransform):BitmapData
	{
		if (piece.height > 2048)
		{
			var pt = new Point(0, 0);
			
			var height_1 = Std.int(piece.height / 2);
			var height_2 = piece.height - height_1;
			
			var piece_1 = new BitmapData(piece.width, height_1, true);
			var piece_2 = new BitmapData(piece.width, height_2, true);
			
			var rect = new Rectangle(0, 0, piece.width, height_1);
			
			piece_1.copyPixels(piece, rect, pt);
			
			rect.y = height_1;
			
			piece_2.copyPixels(piece, rect, pt);
			
			piece_1 = safeColorTransform(piece_1, trans);
			piece_2 = safeColorTransform(piece_2, trans);
			
			piece.copyPixels(piece_1, piece_1.rect, pt);
			pt.y = height_1;
			piece.copyPixels(piece_2, piece_2.rect, pt);
			pt.y = 0;
		}
		else if (piece.width > 2048)
		{
			var pt = new Point(0, 0);
			
			var width_1 = Std.int(piece.width / 2);
			var width_2 = piece.width - width_1;
			
			var piece_1 = new BitmapData(width_1, piece.height, true);
			var piece_2 = new BitmapData(width_1, piece.height, true);
			
			var rect = new Rectangle(0, 0, width_1, piece.height);
			
			piece_1.copyPixels(piece, rect, pt);
			
			rect.x = width_1;
			
			piece_2.copyPixels(piece, rect, pt);
			
			piece_1 = safeColorTransform(piece_1, trans);
			piece_2 = safeColorTransform(piece_2, trans);
			
			piece.copyPixels(piece_1, piece_1.rect, pt);
			pt.x = width_1;
			piece.copyPixels(piece_2, piece_2.rect, pt);
			pt.x = 0;
		}
		else
		{
			piece.colorTransform(piece.rect, trans);
		}
		return piece;
	}
}

typedef LayerSpriteProperty = 
{
	var color:FlxColor;
	var alpha:Float;
	var blend:BlendMode;
}