-- HLE localization. The default and canonical fallback is English, independent
-- of the WoW client locale. Gameplay-sourced boss/item names stay untouched.
local H=HLE;
local strings={
    en={
        appearance="Appearance",alerts="Alerts",profiles="Profiles",advanced="More settings",
        basics="Choose what you see",language="Language",size="Interface size",
        compact="Small",standard="Normal",large="Large",recommended="Recommended",
        meter="Damage meter",equipment="Equipment",party="Party frames",timeline="Boss timeline",
        loot="Loot notices",effects="Buffs and timers",navigation="Guardian navigation",
        jewelry="Jewelry journal",minimap="Minimap skin",bags="Bag skin",
        nameplates="Nameplates",launcher="Minimap settings icon",
        warning_title="Important notifications",danger="Verified danger warnings",
        boss="Boss arrival notifications",rescue="Downed teammate guidance",
        threat_sound="Warning sound",quiet="Hide native center messages",
        skill="Ability ready notifications",summary="Run summary",
        lowhp="Low health threshold",seconds="Repeat interval",
        damage="Damage numbers",healing="Healing numbers",
        normal="Normal",ready="Ready",collapse="Click panel header to fold it",
        profile_intro="Save a layout or restore an existing one.",
        save="Save",load="Load",rename="Rename",empty="Empty",slot="Slot",saved="Saved",loaded="Loaded",
        profile_empty="This slot has no saved layout.",reset="Reset positions",
        reset_question="Click again to confirm",reset_done="Panel positions reset",
        reset_explain="Only layout positions and scale; never character saves.",
        unlock="Move panels",lock="Lock panels",
        status="All changes are saved automatically.",on="On",off="Off",
        close="Close",settings="Settings",open_settings="Left-click: settings",
        move_icon="Shift+drag: move icon",hide_icon_help="Recover icon with /hle launcher",
        scale_help="Resizing keeps every panel in its place.",
        no_run="Run data unavailable",confirmed_hit="HEAVY HIT RECEIVED",
        low_health="DANGER - LOW HEALTH",recover="RECOVER",damage_taken="DAMAGE TAKEN - CHECK HP",
        incoming_boss="BOSS INCOMING",final_boss="FINAL BOSS",profile_name="Profile",
        click_target="Click to target",target_unsupported="Boss targeting unavailable in this client.",
        hud_disabled="HUD disabled; use /hle on to enable.",layout_saved="Layout saved",
        damage_meter="DAMAGE METER",equipment_caps="EQUIPMENT",
        party_caps="PARTY",loot_caps="LOOT",effects_caps="BUFFS / TIMERS",
        navigation_caps="NAVIGATION",jewelry_caps="JEWELRY / JOURNAL",
        kills="KILLS",gold="GOLD",cache="CACHE",enraged="ENRAGED"
    },
    hu={
        appearance="Megjelenés",alerts="Értesítések",profiles="Profilok",advanced="További beállítások",
        basics="Mit szeretnél látni?",language="Nyelv",size="Felület mérete",
        compact="Kicsi",standard="Normál",large="Nagy",recommended="Ajánlott",
        meter="Sebzésmérő",equipment="Felszerelés",party="Csapattársak",timeline="Boss-idővonal",
        loot="Zsákmányértesítések",effects="Buffok és időzítők",navigation="Őrzők navigációja",
        jewelry="Ékszernapló",minimap="Minimapkeret",bags="Táska kinézete",
        nameplates="Névcsíkok",launcher="Beállításikon a minimapnál",
        warning_title="Fontos értesítések",danger="Igazolt veszélyjelzések",
        boss="Boss érkezési jelzések",rescue="Elesett társak mentése",
        threat_sound="Figyelmeztető hang",quiet="Natív középső üzenetek elrejtése",
        skill="Képesség készenlét jelzése",summary="Futamösszesítő",
        lowhp="Alacsony HP küszöb",seconds="Ismétlési idő",
        damage="Sebzésszámok",healing="Gyógyítási számok",
        normal="Normál",ready="Kész",collapse="Panel fejlécére kattintva összecsukható",
        profile_intro="Elrendezés mentése vagy visszaállítása.",
        save="Mentés",load="Betöltés",rename="Átnevezés",empty="Üres",slot="Hely",saved="Mentve",loaded="Betöltve",
        profile_empty="Ezen a helyen nincs mentett elrendezés.",reset="Pozíciók visszaállítása",
        reset_question="Megerősítéshez kattints újra",reset_done="Panelpozíciók visszaállítva",
        reset_explain="Csak panelpozíciók és méret; karaktermentést nem töröl.",
        unlock="Panelek mozgatása",lock="Panelek zárolása",
        status="A beállítások automatikusan mentődnek.",on="Be",off="Ki",
        close="Bezárás",settings="Beállítások",open_settings="Bal kattintás: beállítások",
        move_icon="Shift+húzás: ikon mozgatása",hide_icon_help="Az ikon visszahozható: /hle launcher",
        scale_help="Méretezéskor a panelek a helyükön maradnak.",
        no_run="Nincs futamadat",confirmed_hit="NAGY TALÁLATOT KAPTÁL",
        low_health="VESZÉLY - ALACSONY HP",recover="GYÓGYULJ",damage_taken="KAPOTT SEBZÉS - FIGYELJ A HP-RA",
        incoming_boss="BOSS ÉRKEZIK",final_boss="VÉGSŐ BOSS",profile_name="Profil",
        click_target="Kattints a célzáshoz",target_unsupported="A boss célzása nem támogatott.",
        hud_disabled="A HUD kikapcsolva; /hle on paranccsal visszakapcsolható.",layout_saved="Elrendezés mentve",
        damage_meter="SEBZÉSMÉRŐ",equipment_caps="FELSZERELÉS",party_caps="CSAPAT",
        loot_caps="ZSÁKMÁNY",effects_caps="BUFFOK / IDŐZÍTŐK",navigation_caps="NAVIGÁCIÓ",
        jewelry_caps="ÉKSZERNAPLÓ",kills="ÖLÉSEK",gold="ARANY",cache="LÁDA",enraged="DÜHÖNG"
    },
    de={
        appearance="Anzeige",alerts="Warnungen",profiles="Profile",advanced="Weitere Einstellungen",
        basics="Was möchtest du sehen?",language="Sprache",size="Oberflächengröße",
        compact="Klein",standard="Normal",large="Groß",recommended="Empfohlen",
        meter="Schadensanzeige",equipment="Ausrüstung",party="Gruppenfenster",timeline="Boss-Zeitplan",
        loot="Beutehinweise",effects="Buffs und Timer",navigation="Wächter-Navigation",
        jewelry="Schmucktagebuch",minimap="Minikartenrahmen",bags="Taschendesign",
        nameplates="Namensplaketten",launcher="Einstellungssymbol an Minikarte",
        warning_title="Wichtige Meldungen",danger="Bestätigte Gefahrenwarnungen",
        boss="Boss-Ankunft melden",rescue="Gefallene Mitspieler finden",
        threat_sound="Warnton",quiet="Spielmeldungen in der Mitte ausblenden",
        skill="Fähigkeit bereit melden",summary="Run-Zusammenfassung",
        lowhp="Niedrige Gesundheit",seconds="Wiederholungsabstand",
        damage="Schadenszahlen",healing="Heilungszahlen",
        normal="Normal",ready="Bereit",collapse="Fenstertitel anklicken zum Einklappen",
        profile_intro="Layout speichern oder wiederherstellen.",
        save="Speichern",load="Laden",rename="Umbenennen",empty="Leer",slot="Platz",saved="Gespeichert",loaded="Geladen",
        profile_empty="Auf diesem Platz gibt es kein Layout.",reset="Positionen zurücksetzen",
        reset_question="Zur Bestätigung erneut klicken",reset_done="Positionen zurückgesetzt",
        reset_explain="Nur Layout und Größe, keine Spielstände.",
        unlock="Fenster verschieben",lock="Fenster sperren",
        status="Änderungen werden automatisch gespeichert.",on="An",off="Aus",
        close="Schließen",settings="Einstellungen",open_settings="Linksklick: Einstellungen",
        move_icon="Umschalt+Ziehen: Symbol verschieben",hide_icon_help="Symbol wiederherstellen: /hle launcher",
        scale_help="Beim Skalieren bleiben Fenster an ihrem Platz.",
        no_run="Keine Run-Daten",confirmed_hit="SCHWERER TREFFER ERHALTEN",
        low_health="GEFAHR - WENIG GESUNDHEIT",recover="HEILEN",damage_taken="SCHADEN ERHALTEN - HP PRÜFEN",
        incoming_boss="BOSS KOMMT",final_boss="ENDBOSS",profile_name="Profil",
        click_target="Klicken zum Anvisieren",target_unsupported="Boss-Anvisieren nicht verfügbar.",
        hud_disabled="HUD deaktiviert; /hle on zum Aktivieren.",layout_saved="Layout gespeichert",
        damage_meter="SCHADENSANZEIGE",equipment_caps="AUSRÜSTUNG",party_caps="GRUPPE",
        loot_caps="BEUTE",effects_caps="BUFFS / TIMER",navigation_caps="NAVIGATION",
        jewelry_caps="SCHMUCKTAGEBUCH",kills="KILLS",gold="GOLD",cache="KISTE",enraged="WÜTEND"
    },
    zhCN={
        appearance="外观",alerts="提醒",profiles="配置",advanced="更多设置",
        basics="选择要显示的内容",language="语言",size="界面大小",
        compact="小",standard="标准",large="大",recommended="推荐",
        meter="伤害统计",equipment="装备",party="队伍框架",timeline="首领时间线",
        loot="战利品提示",effects="增益与计时",navigation="守卫导航",
        jewelry="饰品记录",minimap="小地图边框",bags="背包外观",
        nameplates="姓名板",launcher="小地图设置图标",
        warning_title="重要提醒",danger="已确认危险提醒",
        boss="首领出现提醒",rescue="倒地队友指引",
        threat_sound="警报声音",quiet="隐藏游戏中央提示",
        skill="技能就绪提醒",summary="战斗总结",
        lowhp="低生命值阈值",seconds="重复间隔",
        damage="伤害数字",healing="治疗数字",
        normal="普通",ready="准备",collapse="点击面板标题折叠",
        profile_intro="保存或加载界面布局。",
        save="保存",load="加载",rename="重命名",empty="空",slot="栏位",saved="已保存",loaded="已加载",
        profile_empty="此栏位没有保存的布局。",reset="重置位置",
        reset_question="再次点击以确认",reset_done="已重置面板位置",
        reset_explain="仅重置布局与大小，不影响角色存档。",
        unlock="移动面板",lock="锁定面板",
        status="更改会自动保存。",on="开",off="关",
        close="关闭",settings="设置",open_settings="左键：设置",
        move_icon="Shift+拖动：移动图标",hide_icon_help="输入 /hle launcher 恢复图标",
        scale_help="缩放不会改变面板位置。",
        no_run="无战斗数据",confirmed_hit="受到重击",
        low_health="危险 - 生命值过低",recover="恢复生命",damage_taken="已受到伤害 - 注意生命值",
        incoming_boss="首领出现",final_boss="最终首领",profile_name="配置",
        click_target="点击选中目标",target_unsupported="客户端不支持选中首领。",
        hud_disabled="HUD 已关闭；输入 /hle on 开启。",layout_saved="布局已保存",
        damage_meter="伤害统计",equipment_caps="装备",party_caps="队伍",
        loot_caps="战利品",effects_caps="增益 / 计时",navigation_caps="导航",
        jewelry_caps="饰品记录",kills="击杀",gold="金币",cache="宝箱",enraged="狂暴"
    }
};
function H.Language()
    local v=HLE_DB and HLE_DB.language;
    if v=="hu" or v=="de" or v=="zhCN" then return v; end
    return "en";
end
function H.L(key)
    if type(key)~="string" then return ""; end
    return (strings[H.Language()] and strings[H.Language()][key])
        or strings.en[key] or key;
end
function H.LocalizedFont(f,size)
    if not f or type(f.SetFont)~="function" then return; end
    if H.Language()=="zhCN" then
        -- Chinese glyphs require a CJK-capable client. Never ship fonts.
        local ok,success=pcall(f.SetFont,f,"Fonts\\ARKai_T.TTF",size,"OUTLINE");
        if ok and success~=false then return; end
    end
    pcall(f.SetFont,f,"Fonts\\FRIZQT__.TTF",size,"OUTLINE");
end
function H.SetLanguage(v)
    if v~="en" and v~="hu" and v~="de" and v~="zhCN" then return false; end
    HLE_DB.language=v;
    if H.RefreshSettings then H.RefreshSettings(); end
    if H.RefreshCollapseLabels then H.RefreshCollapseLabels(); end
    if H.UpdateMinimapLauncher then H.UpdateMinimapLauncher(); end
    if H.Render and H.Read and H.main then pcall(H.Render,H.Read()); end
    return true;
end
