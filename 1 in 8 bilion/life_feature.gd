extends RefCounted

# === ДЕКЛАРАЦИЯ СОСТОЯНИЯ ===
# Всё это автоматически сохраняется в сейв, откатывается машиной времени.

static func declare_state(fs: Object) -> void:
    # Основные параметры
    fs.declare("character_name", "", {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_age", 0, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_health", 100, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_happiness", 50, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_money", 0, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_career", 0, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_relationships", 50, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_skills", 0, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_profession", "безработный", {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_alive", true, {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("character_city", "", {"personal": true, "rollback": "keep", "epoch": "keep"})
    fs.declare("last_birthday_day", 0, {"personal": true, "rollback": "keep", "epoch": "keep"})
    
    # Флаги действий (ставятся из main.gd, сбрасываются после обработки)
    fs.declare("action_study", false, {"personal": true, "rollback": "reset", "epoch": "reset"})
    fs.declare("action_work", false, {"personal": true, "rollback": "reset", "epoch": "reset"})
    fs.declare("action_doctor", false, {"personal": true, "rollback": "reset", "epoch": "reset"})
    fs.declare("action_relationships", false, {"personal": true, "rollback": "reset", "epoch": "reset"})
    
    # Очередь уведомлений для главного потока
    fs.declare("pending_toasts", [], {"personal": true, "rollback": "reset", "epoch": "reset"})

# === ПОДПИСКА НА ШИНУ ===

static func connect_bus(bus: Object) -> void:
    bus.on("step_rules", Callable(load("res://mods/1-in-8-billion/life_feature.gd"), "_on_step_rules"), 60, "1-in-8-billion")

# === ШАГ МИРА (может выполняться в отдельном потоке!) ===
# ВАЖНО: здесь нельзя трогать UI, нельзя использовать randf()

static func _on_step_rules(game: Node, _days: int) -> void:
    if not Pax.state.value(game.model.features, "character_alive"):
        return
    
    # 1. Обработка действий игрока
    _process_actions(game)
    
    # 2. День рождения?
    var age: int = Pax.state.value(game.model.features, "character_age")
    var last_birthday: int = Pax.state.value(game.model.features, "last_birthday_day")
    if game.model.sim.day - last_birthday >= 365:
        _birthday(game)
    
    # 3. Ежедневные изменения
    _daily_changes(game)
    
    # 4. Случайные события (детерминированно!)
    _random_events(game)

# === ОБРАБОТКА ДЕЙСТВИЙ ===

static func _process_actions(game: Node) -> void:
    # Учеба
    if Pax.state.value(game.model.features, "action_study"):
        var age: int = Pax.state.value(game.model.features, "character_age")
        var skills: int = Pax.state.value(game.model.features, "character_skills")
        var money: int = Pax.state.value(game.model.features, "character_money")
        
        if age < 18:
            skills += 10
            money = max(0, money - 5000)
        else:
            skills += 50
            money = max(0, money - 100000)
            var career: int = Pax.state.value(game.model.features, "character_career")
            career += 1
            Pax.state.set_value(game.model.features, "character_career", career)
        
        Pax.state.set_value(game.model.features, "character_skills", skills)
        Pax.state.set_value(game.model.features, "character_money", money)
        Pax.state.set_value(game.model.features, "action_study", false)
    
    # Работа
    if Pax.state.value(game.model.features, "action_work"):
        var career: int = Pax.state.value(game.model.features, "character_career")
        var health: int = Pax.state.value(game.model.features, "character_health")
        var happiness: int = Pax.state.value(game.model.features, "character_happiness")
        
        var profession: String = _get_profession(career)
        Pax.state.set_value(game.model.features, "character_profession", profession)
        
        health = max(0, health - 5)
        happiness = max(0, happiness - 3)
        Pax.state.set_value(game.model.features, "character_health", health)
        Pax.state.set_value(game.model.features, "character_happiness", happiness)
        Pax.state.set_value(game.model.features, "action_work", false)
    
    # Врач
    if Pax.state.value(game.model.features, "action_doctor"):
        var money: int = Pax.state.value(game.model.features, "character_money")
        var health: int = Pax.state.value(game.model.features, "character_health")
        
        if money >= 5000:
            money -= 5000
            health = min(100, health + 20)
            Pax.state.set_value(game.model.features, "character_money", money)
            Pax.state.set_value(game.model.features, "character_health", health)
        Pax.state.set_value(game.model.features, "action_doctor", false)
    
    # Отношения
    if Pax.state.value(game.model.features, "action_relationships"):
        var relationships: int = Pax.state.value(game.model.features, "character_relationships")
        var happiness: int = Pax.state.value(game.model.features, "character_happiness")
        
        relationships = min(100, relationships + 10)
        happiness = min(100, happiness + 5)
        Pax.state.set_value(game.model.features, "character_relationships", relationships)
        Pax.state.set_value(game.model.features, "character_happiness", happiness)
        Pax.state.set_value(game.model.features, "action_relationships", false)

# === ДЕНЬ РОЖДЕНИЯ ===

static func _birthday(game: Node) -> void:
    var age: int = Pax.state.value(game.model.features, "character_age")
    age += 1
    Pax.state.set_value(game.model.features, "character_age", age)
    Pax.state.set_value(game.model.features, "last_birthday_day", game.model.sim.day)
    
    # Старение после 50
    if age > 50:
        var health: int = Pax.state.value(game.model.features, "character_health")
        health = max(0, health - 2)
        Pax.state.set_value(game.model.features, "character_health", health)
    
    # Смерть от старости (детерминированно!)
    if age > 90:
        var rng: RandomNumberGenerator = Pax.jobs.rng(game.model.sim.day, hash("1-in-8-billion/death"))
        if rng.randf() < (age - 85) / 100.0:
            _die(game, "от старости")

# === ЕЖЕДНЕВНЫЕ ИЗМЕНЕНИЯ ===

static func _daily_changes(game: Node) -> void:
    var profession: String = Pax.state.value(game.model.features, "character_profession")
    if profession != "безработный":
        var money: int = Pax.state.value(game.model.features, "character_money")
        var salary: int = _get_salary(profession)
        money += salary / 30  # Ежедневная зарплата
        Pax.state.set_value(game.model.features, "character_money", money)

# === СЛУЧАЙНЫЕ СОБЫТИЯ (детерминированно!) ===

static func _random_events(game: Node) -> void:
    var rng: RandomNumberGenerator = Pax.jobs.rng(game.model.sim.day, hash("1-in-8-billion/random"))
    var health: int = Pax.state.value(game.model.features, "character_health")
    var money: int = Pax.state.value(game.model.features, "character_money")
    var toasts: Array = Pax.state.value(game.model.features, "pending_toasts")
    
    # Болезнь (5% шанс в день, если здоровье < 70)
    if health < 70 and rng.randf() < 0.05:
        health = max(0, health - 10)
        Pax.state.set_value(game.model.features, "character_health", health)
        toasts.append("Ты заболел. Здоровье ухудшилось.")
    
    # Удачная находка (1% шанс в день)
    if rng.randf() < 0.01:
        var bonus: int = rng.randi() % 10000 + 1000
        money += bonus
        Pax.state.set_value(game.model.features, "character_money", money)
        toasts.append("Неожиданная удача! Ты нашёл " + str(bonus) + "₽.")
    
    if toasts.size() > 0:
        Pax.state.set_value(game.model.features, "pending_toasts", toasts)

# === СМЕРТЬ ===

static func _die(game: Node, reason: String) -> void:
    Pax.state.set_value(game.model.features, "character_alive", false)
    var toasts: Array = Pax.state.value(game.model.features, "pending_toasts")
    var name_val: String = Pax.state.value(game.model.features, "character_name")
    var age: int = Pax.state.value(game.model.features, "character_age")
    toasts.append("К сожалению, " + name_val + " скончался " + reason + " в возрасте " + str(age) + " лет.")
    Pax.state.set_value(game.model.features, "pending_toasts", toasts)

# === ВСПОМОГАТЕЛЬНЫЕ ===

static func _get_profession(career_level: int) -> String:
    if career_level < 1:
        return "стажёр"
    elif career_level < 3:
        return "специалист"
    elif career_level < 6:
        return "менеджер"
    else:
        return "директор"

static func _get_salary(profession: String) -> int:
    var salaries: Dictionary = {
        "безработный": 0,
        "стажёр": 30000,
        "специалист": 60000,
        "менеджер": 120000,
        "директор": 300000
    }
    return salaries.get(profession, 30000)