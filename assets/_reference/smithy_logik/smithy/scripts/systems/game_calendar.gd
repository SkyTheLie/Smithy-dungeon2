class_name GameCalendar
extends RefCounted
## Turns the game's day number (DayCycle.day, day 1 = start) into a date: weekday, day of the
## month, month (season) and year. Names and lengths come from data/content/calendar.json.
## Months have a fixed length (default 28 days = 4 weeks), so each month starts on the same weekday.
## The moon (calendar.json "moon_cycle", "full_moon_day"): full moon every moon_cycle days, the
## first on day full_moon_day (default 14 and 7: the 7th and 21st of every month). On a full moon
## moon lilies are harvested and enchanting potions brewed one rarity tier better.

const DEFAULT_WEEKDAYS: Array = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
const DEFAULT_MONTHS: Array = ["Frühling", "Sommer", "Herbst", "Winter"]


static func get_weekday_names() -> Array:
	return ContentDB.calendar_value("weekdays", DEFAULT_WEEKDAYS)


static func get_weekday_short_names() -> Array:
	var names: Array = ContentDB.calendar_value("weekdays_short", [])
	return names if names.size() == get_weekday_names().size() else get_weekday_names().map(
			func(name: String) -> String: return name.left(2))


static func get_days_per_month() -> int:
	return maxi(1, int(ContentDB.calendar_value("days_per_month", 28)))


static func get_month_names() -> Array:
	return ContentDB.calendar_value("months", DEFAULT_MONTHS)


## 0 = first weekday of the week (Monday by default).
static func get_weekday(day: int) -> int:
	var count: int = get_weekday_names().size()
	return posmod(day - 1 + int(ContentDB.calendar_value("start_weekday", 0)), count)


static func get_weekday_name(day: int) -> String:
	return get_weekday_names()[get_weekday(day)]


static func get_weekday_short(day: int) -> String:
	return get_weekday_short_names()[get_weekday(day)]


## Months since the start (0 = the first month of year 1).
static func get_month_index(day: int) -> int:
	return floori((day - 1) / float(get_days_per_month()))


## Day of the month, 1 ... days_per_month.
static func get_day_of_month(day: int) -> int:
	return posmod(day - 1, get_days_per_month()) + 1


## Game day of the first day of a month (month index as in get_month_index).
static func get_first_day_of_month(month_index: int) -> int:
	return month_index * get_days_per_month() + 1


## Name of the month, e.g. "Frühling".
static func get_month_name(month_index: int) -> String:
	var names: Array = get_month_names()
	return names[posmod(month_index, names.size())]


static func get_year(month_index: int) -> int:
	return floori(month_index / float(get_month_names().size())) + 1


## "Frühling, Jahr 1".
static func get_month_title(month_index: int) -> String:
	return "%s, Jahr %d" % [get_month_name(month_index), get_year(month_index)]


## "3. Frühling".
static func get_date(day: int) -> String:
	return "%d. %s" % [get_day_of_month(day), get_month_name(get_month_index(day))]


## "Mo, 3. Frühling".
static func get_short_text(day: int) -> String:
	return "%s, %s" % [get_weekday_short(day), get_date(day)]


## "Montag, 3. Frühling, Jahr 1".
static func get_long_text(day: int) -> String:
	return "%s, %s, Jahr %d" % [get_weekday_name(day), get_date(day), get_year(get_month_index(day))]


static func get_moon_cycle() -> int:
	return maxi(1, int(ContentDB.calendar_value("moon_cycle", 14)))


static func is_full_moon(day: int) -> bool:
	return posmod(day - int(ContentDB.calendar_value("full_moon_day", 7)), get_moon_cycle()) == 0


## Days until the next full moon (0 = today).
static func get_days_to_full_moon(day: int) -> int:
	return posmod(int(ContentDB.calendar_value("full_moon_day", 7)) - day, get_moon_cycle())
