package funkin.backend.chart;

import funkin.backend.chart.ChartData.ChartMetaData;

// These new structures are kinda a mess to port, i love and hate them at the same time; why the hell are every difficulty in the same file???  - Nex
class BaseGameParser {
	public static function parseChart(data:Dynamic, metaData:Dynamic, result:ChartData) {
		// TO DO
	}

	public static function parseMeta(data:Dynamic, result:ChartMetaData) {
		var data:SwagMetadata = data;
		result.name = data.songName;
		result.artist = data.artist;

		result.customValues = {};
		result.customValues.timeChanges = data.timeChanges;
		var firstTimeChange:SwagTimeChange = data.timeChanges[0];
		result.bpm = firstTimeChange.bpm;
		result.beatsPerMeasure = firstTimeChange.b != null ? firstTimeChange.b : Flags.DEFAULT_BEATS_PER_MEASURE;

		result.difficulties = data.playData.difficulties.concat(data.playData.songVariations);
		Reflect.deleteField(data.playData, "difficulties");

		for (field in Reflect.fields(data.playData))
			Reflect.setProperty(result.customValues, field, Reflect.getProperty(data.playData, field));
	}

	public static function encodeMeta(meta:ChartMetaData, ?chart:ChartData):SwagMetadata {
		var addVars:Dynamic = meta.customValues;
		var defStage:String = addVars.stage != null ? addVars.stage : Flags.DEFAULT_STAGE;
		var defChars:SwagCharactersList = addVars.characters != null ? addVars.characters : {player: Flags.DEFAULT_CHARACTER, girlfriend: Flags.DEFAULT_GIRLFRIEND, opponent: Flags.DEFAULT_OPPONENT};
		var defTimeCh:Array<SwagTimeChange>;

		if (addVars.timeChanges != null && addVars.timeChanges.length > 0) {
			defTimeCh = addVars.timeChanges;
			defTimeCh[0].bpm = meta.bpm;
		}
		else defTimeCh = [{bpm: meta.bpm, t: -1}];

		if (chart != null) {
			defStage = chart.stage;

			var done:Array<Bool> = [false, false, false];
			for (strumLine in chart.strumLines) switch (strumLine.type) {
				case OPPONENT:
					if (!done[0]) {
						done[0] = true;
						defChars.opponent = strumLine.characters.getDefault([defChars.opponent])[0];
					}
				case PLAYER:
					if (!done[1]) {
						done[1] = true;
						defChars.player = strumLine.characters.getDefault([defChars.player])[0];
					}
				case ADDITIONAL:
					if (!done[3]) {
						done[3] = true;
						defChars.girlfriend = strumLine.characters.getDefault([defChars.girlfriend])[0];
					}
			}
		}

		var result:SwagMetadata = {
			songName: meta.name,
			timeFormat: MILLISECONDS,
			artist: meta.artist,
			timeChanges: defTimeCh,
			looped: false,
			generatedBy: 'Basegame Chart Importer (Codename Engine)',
			version: Flags.BASEGAME_SONG_METADATA_VERSION,
			playData: {
				stage: defStage,
				characters: defChars,
				songVariations: addVars.songVariations != null ? [for (i in 0...addVars.songVariations.length) {meta.difficulties.remove(addVars.songVariations[i]); addVars.songVariations[i];}] : [],
				difficulties: meta.difficulties,
				noteStyle: addVars.noteStyle != null ? addVars.noteStyle : Flags.BASEGAME_DEFAULT_NOTE_STYLE,
				album: addVars.album != null ? addVars.album : Flags.BASEGAME_DEFAULT_ALBUM_ID,
				previewStart: addVars.previewStart != null ? addVars.previewStart : Flags.BASEGAME_DEFAULT_PREVIEW_START,
    			previewEnd: addVars.previewEnd != null ? addVars.previewEnd : Flags.BASEGAME_DEFAULT_PREVIEW_END
			},
		};

		return result;
		return null;
	}

	public static function encodeChart(chart:ChartData):NewSwagSong {
		// TO DO
		return null;
	}
}

// METADATA STRUCTURES
typedef SwagMetadata =
{
	var timeFormat:SwagTimeFormat;
	var artist:String;
	var songName:String;
	var playData:SwagPlayData;
	var timeChanges:Array<SwagTimeChange>;
	var generatedBy:String;
	var looped:Bool;
	var version:String;

	var ?divisions:Int;
	var ?offsets:SwagSongOffsets;
}

enum abstract SwagTimeFormat(String) from String to String
{
	var TICKS = 'ticks';
	var FLOAT = 'float';
	var MILLISECONDS = 'ms';
}

typedef SwagTimeChange =
{
	var ?d:Int;  // Time Signature Den
	var ?n:Int;  // Time Signature Num
	var t:Int;  // Time Stamp
	var ?b:Int;  // Beat Time
	var ?bt:Array<Int>;  // Beat Tuplets
	var bpm:Float;
}

typedef SwagPlayData =
{
	var album:String;
	var previewStart:Float;
	var previewEnd:Float;
	var stage:String;
	var characters:SwagCharactersList;
	var songVariations:Array<String>;
	var difficulties:Array<String>;
	var noteStyle:String;
}

typedef SwagCharactersList =
{
	var player:String;
	var girlfriend:String;
	var opponent:String;
}

typedef SwagSongOffsets =
{
	var ?instrumental:Float;
	var ?altInstrumentals:Dynamic;
	var ?vocals:Dynamic;
}

// CHART STRUCTURE
typedef NewSwagSong =
{
	var version:String;
	var scrollSpeed:Dynamic;  // Map<String, Float>
	var events:Array<SwagEvent>;
	var notes:Dynamic;  // Map<String, Array<SwagNote>>
	var generatedBy:String;
}

typedef SwagEvent =
{
	var t:Float;  // Time
	var e:String;  // Event Kind
	var v:Dynamic;  // Value (Map<String, Dynamic>)
}

typedef SwagNote =
{
	var t:Float;  // Time
	var d:Int;  // Data
	var l:Float;  // Length
	var k:String;  // Kind
}