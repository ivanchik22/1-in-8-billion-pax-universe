extends PaxMod

# Ссылка на окно персонажа
var _char_window: Node = null

func _mod_loaded() -> void:
    # 1. Регистрация фичи
    Pax.features.register({
        "id": id,
        "optional": false,
        "title": {"ru": "Симулятор жизни", "en": "Life Simulator"},
        "scripts": ["res://mods/1-in-8-billion/life_feature.gd"],
    })
    
    # 2. Подписки шины (главный поток)
    Pax.bus.on("loaded", Callable(self, "_on_loaded"), 50, id)
    Pax.bus.on("hud_built", Callable(self, "_on_hud_built"), 70, id)
    Pax.bus.on("lore", Callable(self, "_on_lore"), 80, id)
    
    # 3. После шага мира — показываем уведомления (главный поток)
    Pax.bus.on("days_passed", Callable(self, "_on_days_passed"), 50, id)

# === ЗАГРУЗКА ПАРТИИ ===

func _on_loaded(game: Node) -> void:
    var name_val: String = Pax.state.value(game.model.features, "character_name")
    if name_val == "":
        _generate_character(game)
        var age: int = Pax.state.value(game.model.features, "character_age")
        var name_full: String = Pax.state.value(game.model.features, "character_name")
        game.toast("Добро пожаловать в жизнь! Вы — " + name_full + ", вам " + str(age) + " лет.")

# === HUD ===

func _on_hud_built(game: Node) -> void:
    # Кнопки действий
    game.add_bottom_button("🎓 Учиться", func(): _action_study(game))
    game.add_bottom_button("💼 Работать", func(): _action_work(game))
    game.add_bottom_button("🏥 К врачу", func(): _action_doctor(game))
    game.add_bottom_button("❤️ Отношения", func(): _action_relationships(game))
    
    # Кнопка окна персонажа с воксельной моделью
    game.add_bottom_button("👤 Персонаж", func(): _open_character_window(game))

# === ЛОР ДЛЯ НЕЙРОСЕТИ ===

func _on_lore(game: Node, out: Array) -> void:
    var name_val: String = Pax.state.value(game.model.features, "character_name")
    var age: int = Pax.state.value(game.model.features, "character_age")
    var health: int = Pax.state.value(game.model.features, "character_health")
    var profession: String = Pax.state.value(game.model.features, "character_profession")
    var happiness: int = Pax.state.value(game.model.features, "character_happiness")
    var money: int = Pax.state.value(game.model.features, "character_money")
    var city: String = Pax.state.value(game.model.features, "character_city")
    var alive: bool = Pax.state.value(game.model.features, "character_alive")
    
    if not alive:
        out.append("Персонаж " + name_val + " умер.")
        return
    
    out.append("Персонаж: %s, возраст %d лет, живёт в %s, профессия: %s, здоровье: %d%%, счастье: %d%%, деньги: %d₽" % [
        name_val, age, city, profession, health, happiness, money
    ])

# === ПОСЛЕ ШАГА МИРА — ПОКАЗ УВЕДОМЛЕНИЙ ===

func _on_days_passed(game: Node, _from_day: int, _days: int) -> void:
    # Показываем уведомления, накопленные в шаге мира
    var toasts: Array = Pax.state.value(game.model.features, "pending_toasts")
    for msg in toasts:
        game.toast(msg)
    if toasts.size() > 0:
        Pax.state.set_value(game.model.features, "pending_toasts", [])

# === ДЕЙСТВИЯ ИГРОКА (через флаги) ===

func _action_study(game: Node) -> void:
    if Pax.state.value(game.model.features, "character_age") < 7:
        game.toast("Ещё рано учиться!")
        return
    _set_flag(game, "action_study")

func _action_work(game: Node) -> void:
    if Pax.state.value(game.model.features, "character_age") < 16:
        game.toast("Ты ещё слишком молод для работы")
        return
    _set_flag(game, "action_work")

func _action_doctor(game: Node) -> void:
    var money: int = Pax.state.value(game.model.features, "character_money")
    if money < 5000:
        game.toast("Не хватает денег на врача (нужно 5000₽)")
        return
    _set_flag(game, "action_doctor")

func _action_relationships(game: Node) -> void:
    _set_flag(game, "action_relationships")

func _set_flag(game: Node, flag: String) -> void:
    if Pax.world_busy():
        game.when_world_free(func(): Pax.state.set_value(game.model.features, flag, true))
    else:
        Pax.state.set_value(game.model.features, flag, true)

# === ОКНО ПЕРСОНАЖА С ВОКСЕЛЬНОЙ МОДЕЛЬЮ ===

func _open_character_window(game: Node) -> void:
    if _char_window and is_instance_valid(_char_window):
        _char_window.show()
        _char_window.move_to_foreground()
        return
    
    # Загружаем скрипт окна
    var script: GDScript = load("res://mods/1-in-8-billion/character_window.gd")
    _char_window = script.new()
    _char_window.setup(game)
    game.add_child(_char_window)

# === ГЕНЕРАЦИЯ ПЕРСОНАЖА ===

func _generate_character(game: Node) -> void:
    # Детерминированная случайность
    var rng: RandomNumberGenerator = Pax.jobs.rng(game.model.sim.day, hash("1-in-8-billion/character"))
    
    var male_names: Array = ["Александр", "Дмитрий", "Иван", "Сергей", "Андрей", "Михаил", "Николай"]
    var female_names: Array = ["Мария", "Анна", "Елена", "Ольга", "Татьяна", "Наталья", "Екатерина"]
    var surnames: Array = ["Иванов", "Петров", "Сидоров", "Козлов", "Новиков", "Морозов", "Волков", "Соколов"]
    var cities: Array = ["Москва", "Санкт-Петербург", "Новосибирск", "Екатеринбург", "Казань", "Нижний Новгород", "Самара"]
    
    var is_male: bool = rng.randf() < 0.5
    var names: Array = male_names if is_male else female_names
    var name_val: String = names[rng.randi() % names.size()] + " " + surnames[rng.randi() % surnames.size()]
    var age: int = rng.randi() % 25  # 0-24 года
    var money: int = rng.randi() % 100000
    var city: String = cities[rng.randi() % cities.size()]
    
    Pax.state.set_value(game.model.features, "character_name", name_val)
    Pax.state.set_value(game.model.features, "character_age", age)
    Pax.state.set_value(game.model.features, "character_money", money)
    Pax.state.set_value(game.model.features, "character_city", city)
    Pax.state.set_value(game.model.features, "last_birthday_day", game.model.sim.day)