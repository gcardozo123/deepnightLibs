package dn;

import dn.M;

#if( flash||nme||openfl )
import flash.display.Bitmap;
import flash.display.BitmapData;
#if haxe3
import haxe.ds.StringMap.StringMap;
#end
#end

enum Day {
	Sunday;
	Monday;
	Tuesday;
	Wednesday;
	Thursday;
	Friday;
	Saturday;
}

class Lib {
	public static inline function countDaysUntil(now:Date, day:Day) {
		var delta = Type.enumIndex(day) - now.getDay();
		return if(delta<0) 7+delta else delta;
	}

	public static inline function getDay(date:Date) : Day {
		return Type.createEnumIndex(Day, date.getDay());
	}

	public static inline function setTime(date:Date, h:Int, ?m=0,?s=0) {
		var str = "%Y-%m-%d "+StringTools.lpad(""+h,"0",2)+":"+StringTools.lpad(""+m,"0",2)+":"+StringTools.lpad(""+s,"0",2);
		return Date.fromString( DateTools.format(date, str) );
	}

	public static inline function countDeltaDays(now_:Date, next_:Date) {
		var now = setTime(now_, 5);
		var next = setTime(next_, 5);
		return M.floor( (next.getTime() - now.getTime()) / DateTools.days(1) );
	}

	public static inline function leadingZeros(s:Dynamic, ?zeros=2) {
		var str = Std.string(s);
		while (str.length<zeros)
			str="0"+str;
		return str;
	}

	public static inline function repeatChar(c:String, n:Int) {
		var out = "";
		for(i in 0...n)
			out+=c;
		return out;
	}

	#if neko
	public static function drawExcept<T>(a:List<T>, except:T, ?randFn:Int->Int):T {
		if (a.length==0)
			return null;
		if (randFn==null)
			randFn = Std.random;
		var a2 = new Array();
		for (elem in a)
			if (elem!=except)
				a2.push(elem);
		return
			if (a2.length==0)
				null;
			else
				a2[ randFn(a2.length) ];

	}
	#end

	#if openfl
	public static function redirectTraces(func:Dynamic->?haxe.PosInfos->Void) {
		//throw "ERROR";
		#if cpp return;#end
		haxe.Log.trace = func;
	}
	#end


	public static function redirectTracesToConsole(?customPrefix = "") {
		#if ((flash || openfl) && !sys)
		haxe.Log.trace = function(m, ?pos) {
			try {
				if ( pos != null && pos.customParams == null )
					pos.customParams = ["debug"];

				flash.external.ExternalInterface.call("console.log", pos.fileName + "(" + pos.lineNumber + ") : " + customPrefix + Std.string(m));
			}
			catch (e:Dynamic) {}
		}
		#else
		trace("cannot redirect to console !");
		#end
	}

	#if( h3d || heaps )
	public static function redirectTracesToH2dConsole(c:h2d.Console) {
		haxe.Log.trace = function(m, ?pos) {
			if ( pos != null && pos.customParams == null )
				pos.customParams = ["debug"];

			c.log(pos.fileName + "(" + pos.lineNumber + ") : " + Std.string(m));
		}
	}
	#end

	#if h3d
   /**
	* guarantees that the screen will return some correctly size bitmap...
	*/
	public static function h2dScreenshot(s:h2d.Scene, ?target:h2d.Tile, ?bindDepth=false) : h2d.Bitmap {
		var engine = h3d.Engine.getCurrent();
		var ww = Math.round(s.width);
		var wh = Math.round(s.height);

		var tw = hxd.Math.nextPow2(ww);
		var th = hxd.Math.nextPow2(wh);

		if( target == null ) {
			var tex = new h3d.mat.Texture(tw, th, h3d.mat.Texture.TargetFlag());
			target = new h2d.Tile(tex, 0, 0, tw, th);
			target.scaleToSize(ww, wh);
			#if cpp
			target.targetFlipY();
			#end
		}

		engine.triggerClear = true;

		var tex = target.getTexture();
		engine.setTarget(tex, bindDepth);
		engine.setRenderZone();

		engine.begin();
		s.render(engine);
		engine.end();

		s.set_posChanged(true);

		engine.setTarget(null, false, null);
		engine.setRenderZone();

		return new h2d.Bitmap(target);
	}
	#end


	#if flash9
	public static inline function isMac() {
		return flash.system.Capabilities.os.indexOf("mac")>=0;
	}

	public static inline function isAndroid() {
		return flash.system.Capabilities.version.indexOf("AND")>=0;
	}

	public static inline function isIos() {
		return flash.system.Capabilities.version.indexOf("IOS")>=0;
	}

	public static inline function isAir() {
		return flash.system.Capabilities.playerType=="Desktop";
	}

	public static function getFlashVersion() { // renvoie Float sous la forme "11.2"
		var ver = flash.system.Capabilities.version.split(" ")[1].split(",");
		return Std.parseFloat(ver[0]+"."+ver[1]);
	}

	public static function atLeastVersion(version:String) { // format : xx.xx.xx.xx ou xx,xx,xx,xx
		var s = StringTools.replace(version, ",", ".");
		var req = s.split(".");
		var fv = flash.system.Capabilities.version;
		var mine = fv.substr(fv.indexOf(" ")+1).split(",");
		for (i in 0...req.length) {
			if (mine[i]==null || req[i]==null)
				break;
			var m = Std.parseInt(mine[i]);
			var r = Std.parseInt(req[i]);
			if ( m>r )	return true;
			if ( m<r )	return false;

		}
		return true;
	}
	#end

	#if( flash9 || openfl || sys )
	//public static function testCookies() {
		//try {
			//var cookie = flash.net.SharedObject.getLocal("cchk");
			//Reflect.setField(cookie.data, "chk", 1);
			//cookie.flush();
			//var cookie = flash.net.SharedObject.getLocal("cchk");
			//return Reflect.field(cookie.data, "chk") == 1;
		//}
		//catch( e:Dynamic ) {
			//return false;
		//}
	//}
	inline static function _getLocalCookie( cookieName ){
		#if (flash || openfl)
		return flash.net.SharedObject.getLocal( cookieName );
		#elseif sys
		return new LocalCookie( cookieName );
		#end
	}

	public static function getCookie(cookieName:String, varName:String, ?defValue:Dynamic) : Dynamic {
		try {
			var cookie = _getLocalCookie(cookieName);
			return
				if ( Reflect.hasField(cookie.data, varName) )
					Reflect.field(cookie.data, varName);
				else
					defValue;
		}
		catch( e:Dynamic ) {
			return defValue;
		}
	}

	public static function setCookie(cookieName:String, varName:String, value:Dynamic) {
		try {
			var cookie = _getLocalCookie(cookieName);
			Reflect.setField(cookie.data, varName, value);
			cookie.flush();
			return true;
		}
		catch( e:Dynamic ) {
			return false;
		}
	}

	public static function removeCookie(cookieName:String, varName:String) {
		try {
			var cookie = _getLocalCookie(cookieName);
			if( cookie!=null ) {
				Reflect.deleteField(cookie.data, varName);
				cookie.flush();
			}
			return true;
		}
		catch( e:Dynamic ) {
			return false;
		}
	}

	public static function resetCookie(cookieName:String, ?obj:Dynamic) {
		try {
			var cookie = _getLocalCookie(cookieName);
			cookie.clear();
			if (obj!=null)
				for (key in Reflect.fields(obj))
					Reflect.setField(cookie.data, key, Reflect.field(obj, key));
			cookie.flush();
			return true;
		}
		catch( e:Dynamic ) {
			return false;
		}
	}
	#end

	#if (flash || openfl)
	public static inline function constraintBox(o:flash.display.DisplayObject, maxWid, maxHei) {
		var r = M.fmin( M.fmin(1, maxWid/o.width), M.fmin(1, maxHei/o.height) );
		o.scaleX = r;
		o.scaleY = r;
		return r;
	}

	public static inline function isOverlap(a:flash.geom.Rectangle, b:flash.geom.Rectangle) : Bool {
		return
			b.x>=a.x-b.width && b.x<=a.right &&
			b.y>=a.y-b.height && b.y<=a.bottom;
	}
	#end



	/**
	 * Shuffle an array in place
	 */
	public static function shuffleArray<T>(arr:Array<T>, randFunc:Int->Int) {
		// WARNING!! Now modifies the array itself (changed on Apr. 27 2016)
		// Source: http://bost.ocks.org/mike/shuffle/
		var m = arr.length;
		var i = 0;
		var tmp = null;
		while( m>0 ) {
			i = randFunc(m--);
			tmp = arr[m];
			arr[m] = arr[i];
			arr[i] = tmp;
		}
	}

	/**
	 * Shuffle a vector in place
	 */
	public static function shuffleVector<T>(arr:haxe.ds.Vector<T>, randFunc:Int->Int) {
		// Source: http://bost.ocks.org/mike/shuffle/
		var m = arr.length;
		var i = 0;
		var tmp = null;
		while( m>0 ) {
			i = randFunc(m);
			m--;
			tmp = arr[m];
			arr[m] = arr[i];
			arr[i] = tmp;
		}
	}

	public static function randomSpread(total:Int, nbStacks:Int, ?maxStackValue:Null<Int>, randFunc:Int->Int) : Array<Int> {
		if (total<=0 || nbStacks<=0)
			return new Array();

		if( maxStackValue!=null && total/nbStacks>maxStackValue ) {
			var a = [];
			for(i in 0...nbStacks)
				a.push(maxStackValue);
			return a;
		}

		if( nbStacks>total ) {
			var a = [];
			for(i in 0...total)
				a.push(1);
			return a;
		}

		var plist = new Array();
		for (i in 0...nbStacks)
			plist[i] = 1;

		var remain = total-plist.length;
		while (remain>0) {
			var move = M.ceil(total*(randFunc(8)+1)/100);
			if (move>remain)
				move = remain;

			var p = randFunc(nbStacks);
			if( maxStackValue!=null && plist[p]+move>maxStackValue )
				move = maxStackValue - plist[p];
			plist[p]+=move;
			remain-=move;
		}
		return plist;
	}


	public static inline function constraint(n:Dynamic, min:Dynamic, max:Dynamic) {
		return
			if (n<min) min;
			else if (n>max) max;
			else n;
	}

	public static inline function replaceTag(str:String, char:String, open:String, close:String) {
		var char = "\\"+char.split("").join("\\");
		var re = char+"([^"+char+"]+)"+char;
		return try { new EReg(re, "g").replace(str, open+"$1"+close); } catch (e:String) { str; }
	}

	public static inline function getNextPower2(n:Int) { // n est sur 32 bits
		n--;
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		n |= n >> 8;
		n |= n >> 16;
		return n+1;
	}

	public static inline function getNextPower2_8bits(n:Int) { // n est sur 8 bits
		n--;
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		return n+1;
	}

	public static inline function rnd(min:Float, max:Float, sign=false) {
		if( sign )
			return (min + Math.random()*(max-min)) * (Std.random(2)*2-1);
		else
			return min + Math.random()*(max-min);
	}

	public static inline function irnd(min:Int, max:Int, sign=false) {
		if( sign )
			return (min + Std.random(max-min+1)) * (Std.random(2)*2-1);
		else
			return min + Std.random(max-min+1);
	}


	public static function splitUrl(url:String) {
		if( url==null || url.length==0 )
			return null;
		var noProt = if( url.indexOf("://")<0 ) url else url.substr( url.indexOf("://")+3 );
		return {
			prot	: if( url.indexOf("://")<0 ) null else url.substr(0, url.indexOf("://")),
			dom		: if( noProt.indexOf("/")<0 ) noProt else if( noProt.indexOf("/")==0 ) null else noProt.substr(0, noProt.indexOf("/")),
			path	: if( noProt.indexOf("/")<0 ) "/" else noProt.substr(noProt.indexOf("/")),
		}
	}

	public static function splitMail(mail:String) {
		if (mail==null || mail.length==0)
			return null;
		if (mail.indexOf("@")<0)
			return null;
		else {
			var a = mail.split("@");
			if ( a[1].indexOf(".")<0 )
				return null;
			else
				return {
					usr	: a[0],
					dom	: a[1].substr(0,a[1].indexOf(".")),
					ext	: a[1].substr(a[1].indexOf(".")+1),
				}
		}
	}

	#if (flash9 || nme || openfl)
	public static function flatten(o:flash.display.DisplayObject, padding=0.0, copyTransforms=false, ?quality) {
		// Change quality
		var qold = try { flash.Lib.current.stage.quality; } catch(e:Dynamic) { flash.display.StageQuality.MEDIUM; };
		if( quality!=null )
			try {
				flash.Lib.current.stage.quality = quality;
			} catch( e:Dynamic ) {
				throw("Flatten quality error");
			}

		// Cancel transforms to draw into BitmapData
		var b = o.getBounds(o);
		var bmp = new flash.display.Bitmap( new flash.display.BitmapData(M.ceil(b.width+padding*2), M.ceil(b.height+padding*2), true, 0x0) );
		var m = new flash.geom.Matrix();
		m.translate(-b.x, -b.y);
		m.translate(padding, padding);
		bmp.bitmapData.draw(o, m, o.transform.colorTransform);

		// Apply transforms to Bitmap parent
		var m = new flash.geom.Matrix();
		m.translate(b.x, b.y);
		m.translate(-padding, -padding);
		if( copyTransforms ) {
			m.scale(o.scaleX, o.scaleY);
			m.rotate( M.toRad(o.rotation) );
			m.translate(o.x, o.y);
		}
		bmp.transform.matrix = m;

		// Restore quality
		if( quality!=null )
			try {
				flash.Lib.current.stage.quality = qold;
			} catch( e:Dynamic ) {
				throw("Flatten quality error");
			}
		return bmp;
	}


	public static function createTexture(source:flash.display.BitmapData, width:Float, height:Float, autoDisposeSource:Bool) {
		var bd = new BitmapData(M.ceil(width), M.ceil(height), source.transparent, 0x0);
		bd.lock();

		var pt = new flash.geom.Point();
		for(x in 0...M.ceil(width/source.width))
			for(y in 0...M.ceil(height/source.height)) {
				pt.x = x * source.width;
				pt.y = y * source.height;
				bd.copyPixels(source, source.rect, pt, source, true);
			}

		bd.unlock();

		if( autoDisposeSource ) {
			source.dispose();
			source = null;
		}
		return bd;
	}


	public static function scaleBitmap(source:BitmapData, scale:Float, ?q:flash.display.StageQuality, disposeSource:Bool) {
		var bd = new BitmapData( M.round(source.width*scale), M.round(source.height*scale), source.transparent, 0x0 );
		var m = new flash.geom.Matrix();
		m.scale(scale, scale);

		#if (flash11_3 && !openfl)
		if( q!=null )
			bd.drawWithQuality(source, m, false, q);
		else
		#end
			bd.draw(source, m);

		if( disposeSource )
			source.dispose();

		return bd;
	}


	public static function flipBitmap(bd:BitmapData, flipX:Bool, flipY:Bool) {
		var tmp = bd.clone();
		var m = new flash.geom.Matrix();
		if( flipX ) {
			m.scale(-1, 1);
			m.translate(bd.width, 0);
		}
		if( flipY ) {
			m.scale(1, -1);
			m.translate(0, bd.height);
		}
		bd.draw(tmp, m);
		tmp.dispose();
	}
	#end



	public static function makeXmlNode(name:String, ?attributes:Map<String, String>, ?inner:String) {
		if( attributes==null && inner==null )
			return '<$name/>';

		var a = [];
		for(k in attributes.keys())
			a.push( k+"='"+attributes.get(k)+"'" );

		var begin = '<$name ${a.join(" ")}';
		var end = inner!=null ? '>$inner</$name>' : "/>";
		return begin+end;
	}


	#if flash
	public static function loadFile(onComplete:flash.utils.ByteArray->flash.net.FileReference->Void) {
		var file = new flash.net.FileReference();
		file.addEventListener(flash.events.Event.SELECT, function(_) {
			file.load();
		});
		file.addEventListener(flash.events.Event.COMPLETE, function(_) {
			onComplete(file.data, file);
		});
		file.browse();
	}


	public static function saveFile(defaultName:String, data:String, ?onComplete:Void->Void) {
		var file = new flash.net.FileReference();
		file.addEventListener(flash.events.Event.COMPLETE, function(_) if( onComplete!=null ) onComplete() );
		file.save(data, defaultName);
	}
	#end



	public static inline function prettyTime(t:Float) : String {
		if( t<=DateTools.days(365) ) {
			// Duration
			var s = M.fabs(t)/1000;
			var m = s/60;
			var h = m/60;
			h = Std.int(h%24);
			return (t<0?"-":"") + (h>0?h+"h ":"") + leadingZeros(Std.int(m%60))+"m "+leadingZeros(Std.int(s%60))+"s";
		}
		else {
			// Probably really a timestamp
			return DateTools.format(Date.fromTime(t), "%Hh %Mm %Ss (%Y-%m-%d)");
		}
	}


	#if flash
	static var LAST_COPY_CANCEL : Void->Void = null;
	public static function h2dCopyToClipboard(o:Dynamic) {
		if( LAST_COPY_CANCEL!=null )
			LAST_COPY_CANCEL();

		var s = new flash.display.Sprite();
		flash.Lib.current.addChild(s);
		s.graphics.beginFill(0x0080FF,1);
		s.graphics.drawRect(10,10, 200,50);

		var tf = new flash.text.TextField();
		s.addChild(tf);
		tf.text = "Press C to confirm copy";
		tf.x = tf.y = 10;
		tf.textColor = 0xFFFFFF;
		tf.width = 200;
		tf.selectable = tf.mouseEnabled = false;

		var cancelRef = null;
		function onKeyDown(e:flash.events.KeyboardEvent) {
			if( e.keyCode==flash.ui.Keyboard.C )
				flash.system.System.setClipboard( Std.string(o) );
			cancelRef();
		}

		var t = 0;
		function onEnterFrame(_) {
			if( t>=flash.Lib.current.stage.frameRate*3 )
				cancelRef();
			else
				t++;
		}

		function cancel() {
			flash.Lib.current.stage.removeEventListener( flash.events.KeyboardEvent.KEY_DOWN, onKeyDown );
			flash.Lib.current.stage.removeEventListener( flash.events.Event.ENTER_FRAME, onEnterFrame );
			s.parent.removeChild(s);
			s = null;
			cancelRef = null;
			LAST_COPY_CANCEL = null;
		}
		cancelRef = cancel;
		LAST_COPY_CANCEL = cancel;

		flash.Lib.current.stage.addEventListener( flash.events.Event.ENTER_FRAME, onEnterFrame );
		flash.Lib.current.stage.addEventListener( flash.events.KeyboardEvent.KEY_DOWN, onKeyDown );
	}
	#end

	public static function ludumProtection(p:dn.Process, ?allowLocal=true) : Bool {
		var ok = false;
		var s = "d"+"e"+"e"+"p"+""+"n"+"i"+""+"g"+""+"h"+"t";

		#if flash
			var d = flash.system.Security.pageDomain;
			var url = flash.Lib.current.stage.loaderInfo.url;
			ok =
				d!=null && d.indexOf(s+"."+"n"+"e"+"t")>=0
				|| url.indexOf("app:/")==0 // AIR
				|| allowLocal && url!=null && url.indexOf(s)>=0 && url.indexOf("fi"+"le"+":")>=0; // local file
		#elseif js
			var d = js.Browser.document.URL;
			ok =
				d.indexOf(s+"."+"n"+"e"+"t")>=0
				|| allowLocal && d.indexOf("file://")==0;
		#else
			ok = true;
		#end

		#if debug
		ok = true;
		#end

		if( !ok ) {
			p.delayer.addS(function() {
				p.cd = null; // crash randomly later
			}, rnd(4,7));
		}

		return ok;
	}

	public static function getUserAgent() : String {
		#if flash
		try{
			var userAgent = flash.external.ExternalInterface.call("window.navigator.userAgent.toString");
			return
				if( userAgent.indexOf("Chrome") != -1 )			"chrome";
				else if( userAgent.indexOf("Safari") != -1 )	"safari";
				else if( userAgent.indexOf("Firefox") != -1 )	"firefox";
				else if( userAgent.indexOf("MSIE") != -1 )		"ie";
				else if( userAgent.indexOf("Opera") != -1 )		"opera";
				else "unknown";
		}
		catch (e:Dynamic) {
			// Could not access ExternalInterface in containing page
			return "unknown";
		}
		#else
		return "unknown";
		#end
	}

	public static function getEnumMetaFloat<T:EnumValue>(e:T, varName:String, ?def=0.) : Float {
		var meta = haxe.rtti.Meta.getFields( Type.getEnum(e) );
		if( meta==null )
			return def;

		var f = Reflect.field(meta, Type.enumConstructor(e));
		if( f==null || !Reflect.hasField(f,varName) || !Std.is(Reflect.field(f,varName)[0], Float) )
			return def;

		var v : Float = Reflect.field(f,varName)[0];
		return Math.isNaN(v) ? def : v;
	}

	public static inline function getEnumMetaInt<T:EnumValue>(e:T, varName:String, ?def=0) : Int {
		return Std.int( getEnumMetaFloat(e, varName, def) );
	}


	#if heaps
	static var fullscreenEnabled = false;
	public static function enableFullscreen(p:dn.Process, ?alternativeKey:Int, button:Bool) {
		if( fullscreenEnabled )
			return;

		fullscreenEnabled = true;

		#if js

		var canvas = js.Browser.document.getElementById("webgl");

		if( button ) {
			var w = 24;
			var g = new h2d.Graphics(Boot.ME.s2d);
			g.alpha = 0.7;
			g.blendMode = None;
			g.beginFill(0x0,1);
			g.drawRect(0,0,w,w);
			g.endFill();

			g.lineStyle(2,0xffffff,1);
			g.moveTo(w*0.1, w*0.3);
			g.lineTo(w*0.1, w*0.1);
			g.lineTo(w*0.3, w*0.1);
			g.moveTo(w*0.1,w*0.1);
			g.lineTo(w*0.35, w*0.35);

			g.moveTo(w*0.7, w*0.1);
			g.lineTo(w*0.9, w*0.1);
			g.lineTo(w*0.9, w*0.3);
			g.moveTo(w*0.9,w*0.1);
			g.lineTo(w*0.65, w*0.35);

			g.moveTo(w*0.9, w*0.7);
			g.lineTo(w*0.9, w*0.9);
			g.lineTo(w*0.7, w*0.9);
			g.moveTo(w*0.9,w*0.9);
			g.lineTo(w*0.65, w*0.65);

			g.moveTo(w*0.1, w*0.7);
			g.lineTo(w*0.1, w*0.9);
			g.lineTo(w*0.3, w*0.9);
			g.moveTo(w*0.1,w*0.9);
			g.lineTo(w*0.35, w*0.65);

			canvas.addEventListener( "click", function(e) {
				var rect = canvas.getBoundingClientRect();
				var x = e.clientX - rect.left;
				var y = e.clientY - rect.top;
				if( !isFullscreen() && x>=g.x && x<g.x+w && y>=g.y && y<g.y+w )
					toggleFullscreen();
			});

			p.createChildProcess( function(_) {
				g.x = p.w()-w-2;
				g.y = 2;
				g.visible = !isFullscreen();
			});
		}

		canvas.addEventListener("keydown",function(e) {
			if( alternativeKey!=null && e.keyCode==alternativeKey || e.keyCode==hxd.Key.ENTER && e.altKey || e.keyCode==hxd.Key.F11 )
				toggleFullscreen();
		});

		#else

		p.createChildProcess( function(_) {
			if( alternativeKey!=null && hxd.Key.isPressed(alternativeKey) || hxd.Key.isDown(hxd.Key.ALT) && hxd.Key.isPressed(hxd.Key.ENTER) || hxd.Key.isPressed(hxd.Key.F11) )
				toggleFullscreen();
		});

		#end
	}

	public static inline function isFullscreen() {
		#if js
		return (cast js.Browser.document).fullscreen;
		#elseif hl
		return h3d.Engine.getCurrent().fullScreen;
		#else
		return false;
		#end
	}
	public static function toggleFullscreen() {
		#if js
		if( isFullscreen() )
			(cast js.Browser.document).exitFullscreen();
		else
			(cast js.Browser.document.getElementById("webgl")).requestFullscreen(); // Warning: only works if called from a user-generated event
		#else
		h3d.Engine.getCurrent().fullScreen = !h3d.Engine.getCurrent().fullScreen;
		#end
	}
	#end

} // End of Lib


#if (!(flash||openfl) && sys)
private class LocalCookie {
	public var name : String;
	public var data : Dynamic;

	public function new( name : String ){
		this.name = name;

		var p = path();
		if( sys.FileSystem.exists(p) )
			data = try haxe.Unserializer.run(sys.io.File.getContent(path())) catch( e : Dynamic ) {};
		else
			clear();
	}

	public function flush(){
		var d = Sys.getCwd()+"/_cookies";
		if( !sys.FileSystem.exists(d) )
			sys.FileSystem.createDirectory(d);

		sys.io.File.saveContent(path(), haxe.Serializer.run(data));
	}

	public inline function clear(){
		data = {};
	}

	inline function path(){
		return Sys.getCwd()+"/_cookies/"+name;
	}
}
#end
