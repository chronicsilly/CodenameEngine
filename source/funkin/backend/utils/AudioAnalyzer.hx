package funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;

// Thank you yosh :DDD -lunar
// (https://github.com/CodenameCrew/YoshiCrafterEngine/blob/main/source/WaveformSprite.hx)
class AudioAnalyzer {
	public var buffer:AudioBuffer;
	var __peakByte:Float = 0;
	var __timeMulti:Float = 0;

	public function new(sound:FlxSound) {
		@:privateAccess buffer = sound._sound.__buffer;

		__peakByte = Math.pow(2, buffer.bitsPerSample-1)-1;

		__timeMulti = 1 / (1 / buffer.sampleRate);
		__timeMulti *= buffer.bitsPerSample;
		__timeMulti -= __timeMulti % buffer.bitsPerSample;
	}

	public function analyze(startPos:Float, endPos:Float):Float {
		var bitsPerSample = buffer.bitsPerSample;
		var multi = __timeMulti / 4000 / bitsPerSample;
		var bytesStartPos:Int = Math.floor(startPos * multi) * bitsPerSample;
		var bytesEndPos:Int = Math.floor(endPos * multi) * bitsPerSample;

		bytesStartPos -= bytesStartPos % bitsPerSample;
		bytesEndPos -= bytesEndPos % bitsPerSample;

		var dataBuffer = buffer.data.buffer;

		var maxByte:Int = 0;
		for(i in 0...Math.floor((bytesEndPos - bytesStartPos) / bitsPerSample)) {
			var bytePos = bytesStartPos + (i * bitsPerSample);
			// What if bitsPerSample is 8? or 32? or 64? -Ne_Eo
			var byte:Int = dataBuffer.get(bytePos) | (dataBuffer.get(bytePos + 1) << 8);
			if (byte > 256 * 128) byte -= 256 * 256;
			if (maxByte < byte) maxByte = byte;
		}

		return maxByte/__peakByte;
	}
}