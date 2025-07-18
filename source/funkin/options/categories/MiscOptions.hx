package funkin.options.categories;


class MiscOptions extends OptionsScreen {
	public override function new() {
		super("Miscellaneous", "Use this menu to reset save data or engine settings.");
		#if UPDATE_CHECKING
		add(new Checkbox(
			"Enable Nightly Updates",
			"If checked, will also include nightly builds in the update checking.",
			"betaUpdates"));,
		add(new TextOption(
			"Check for Updates",
			"Select this option to check for new engine updates.",
			function() {
				var report = funkin.backend.system.updating.UpdateUtil.checkForUpdates();
				if (report.newUpdate) {
					FlxG.switchState(new funkin.backend.system.updating.UpdateAvailableScreen(report));
				} else {
					CoolUtil.playMenuSFX(CANCEL);
					updateDescText("No update found.");
				}
		}));,
		#end
		add(new Checkbox(
			"Yuri",
			"If checked, will open yxtwitter randomly.",
			"lesbiab"));
		add(new ArrayOption(
			"Pronouns",
			"Woke...?",
			["they", "she", "he"],
			["They/Them", "She/Her", "He/Him"],
			"pronouns"
		));
		add(new TextOption(
			"Reset Save Data",
			"Select this option to reset save data. This will remove all of your highscores.",
			function() {
				// TODO: SAVE DATA RESETTING
		}));
	}
}
