class_name SoundSynth
extends RefCounted
## Short sounds made in code, so every enemy can have its own voice without sound files.
## A voice (data/enemies.json "voice" and "cries", data/player.json "voice"):
##   wave   "square", "saw", "sine", "triangle" or "noise"
##   freq   start pitch in Hz           slide  pitch at the end, times freq (0.5 = falls an octave)
##   length seconds                     noise  0..1 noise mixed in (growl, crunch)
##   vibrato  wobble of the pitch (0..1)
## Optional (for the animal cries, defaults = the old short sound):
##   noise_end  noise at the end (0.3 -> 1.0 = a voiced "wa" turning into a hiss "chhh")
##   rough      noise held for this many samples (1 = sharp hiss, 6 = low growl), default 3
##   rise       part of the length the sound swells up (0.03 = hard start, 0.5 = slow swell)
##   fade       how fast it fades after that (higher = shorter tail), default 1.6
##   tremolo    choppings per second (20-35 = chittering, clicking, rattling), 0 = none
##   repeat     the sound this many times in a row ("fiep fiep"), gap = seconds between them,
##              repeat_pitch = pitch of every next one, times the one before
## make() builds the sound once per voice and kind ("hit" short, "die" longer and lower, anything
## else exactly as written) and keeps it (read-only cache).

const MIX_RATE: int = 22050

static var _cache: Dictionary[String, AudioStreamWAV] = {}


static func make(voice: Dictionary, kind: String) -> AudioStreamWAV:
	var key: String = "%s|%s" % [JSON.stringify(voice), kind]
	if _cache.has(key):
		return _cache[key]
	var length: float = float(voice.get("length", 0.12))
	var freq: float = float(voice.get("freq", 300.0))
	var slide: float = float(voice.get("slide", 0.7))
	if kind == "die":
		length *= 2.6
		slide *= 0.6
		freq *= 0.85
	var repeat: int = clampi(int(voice.get("repeat", 1)), 1, 8)
	var gap: int = int(maxf(0.0, float(voice.get("gap", 0.05))) * MIX_RATE)
	var repeat_pitch: float = float(voice.get("repeat_pitch", 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var data := PackedByteArray()
	for r in repeat:
		if r > 0:
			var silence := PackedByteArray()
			silence.resize(gap * 2)
			silence.fill(0)
			data.append_array(silence)
		data.append_array(_chirp(voice, freq * pow(repeat_pitch, r), slide, length, rng))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	_cache[key] = stream
	return stream


## One sound of `length` seconds as 16 bit samples.
static func _chirp(voice: Dictionary, freq: float, slide: float, length: float, rng: RandomNumberGenerator) -> PackedByteArray:
	var wave: String = String(voice.get("wave", "square"))
	var noise_start: float = clampf(float(voice.get("noise", 0.2)), 0.0, 1.0)
	var noise_end: float = clampf(float(voice.get("noise_end", noise_start)), 0.0, 1.0)
	if wave == "noise":
		noise_start = 1.0
		noise_end = 1.0
	var vibrato: float = float(voice.get("vibrato", 0.0))
	var rough: int = maxi(1, int(voice.get("rough", 3)))
	var rise: float = clampf(float(voice.get("rise", 1.0 / 30.0)), 0.005, 0.95)
	var fade: float = maxf(0.1, float(voice.get("fade", 1.6)))
	var tremolo: float = maxf(0.0, float(voice.get("tremolo", 0.0)))
	var count: int = maxi(1, int(length * MIX_RATE))
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	var held: float = 0.0
	for i in count:
		var t: float = float(i) / count
		var f: float = freq * lerpf(1.0, slide, t) * (1.0 + sin(t * 40.0) * vibrato * 0.08)
		phase = fmod(phase + f / MIX_RATE, 1.0)
		var tone: float = 0.0
		match wave:
			"square":
				tone = 1.0 if phase < 0.5 else -1.0
			"saw":
				tone = phase * 2.0 - 1.0
			"triangle":
				tone = 1.0 - absf(phase * 4.0 - 2.0)
			"sine":
				tone = sin(phase * TAU)
		# Noise is held for a few samples (more = rougher, lower).
		if i % rough == 0:
			held = rng.randf_range(-1.0, 1.0)
		var sample: float = lerpf(tone, held, lerpf(noise_start, noise_end, t))
		# Swells up for `rise`, then fades out.
		var envelope: float = t / rise if t < rise else pow((1.0 - t) / (1.0 - rise), fade)
		if tremolo > 0.0 and sin(TAU * tremolo * t * length) < 0.0:
			envelope *= 0.15
		var value: int = clampi(int(sample * envelope * 0.55 * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, value)
	return data
