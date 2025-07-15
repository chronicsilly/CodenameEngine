package funkin.backend.scripting.events.healthicon;

final class HealthIconChangeEvent extends CancellableEvent {
	/**
	 * Amount
	 */
	public var amount:Int;

	/**
	 * The health icon
	 */
	public var healthIcon:funkin.game.HealthIcon;
}