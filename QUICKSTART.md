# 🚀 Quick Start - Block Master

## 1. Abrir no Godot 4
```
Godot 4 → Importar → Selecione pasta BlockMaster → Importar e Editar
```

## 2. Instalar Plugins (OBRIGATÓRIO)
Baixe e extraia cada um em `addons/`:

| Plugin | Link | Pasta |
|--------|------|-------|
| GodotPayment | https://github.com/godotengine/godot-payment-plugin | addons/godotpayment/ |
| GodotAdMob | https://github.com/godotengine/godot-admob-plugin | addons/godotadmob/ |
| GodotPlayGamesServices | https://github.com/godotengine/godot-play-games-services | addons/godotplaygamesservices/ |
| GodotNotifications | https://github.com/godotengine/godot-notifications | addons/godotnotifications/ |

No Godot: **Projeto → Plugins → Ative os 4**

## 3. Configurar Seus IDs
Edite estes 2 arquivos com seus IDs do Google Play Console:

**`scripts/autoload/MonetizationManager.gd`** (linha ~15):
```gdscript
const AD_UNITS = {
    "interstitial": "ca-app-pub-SEU_ID/SEU_INTERSTITIAL",
    "rewarded": "ca-app-pub-SEU_ID/SEU_REWARDED",
    "banner": "ca-app-pub-SEU_ID/SEU_BANNER",
    "app_open": "ca-app-pub-SEU_ID/SEU_APP_OPEN"
}
```

**`scripts/autoload/LeaderboardManager.gd`** (linha ~10):
```gdscript
var _leaderboard_id_high_score = "SEU_LEADERBOARD_GLOBAL"
var _leaderboard_id_weekly = "SEU_LEADERBOARD_SEMANAL"
var _leaderboard_id_daily = "SEU_LEADERBOARD_DIARIO"
# + 12 achievements IDs
```

## 4. Package Name
Em `export_presets.cfg`:
```
package_name="com.SEU_NOME.blockmaster"
```

## 5. Keystore Release
```bash
keytool -genkey -v -keystore release.keystore -alias blockmaster -keyalg RSA -keysize 2048 -validity 10000
```
Edite `user.properties` com suas senhas.

No Godot: **Exportar → Android → Keystore Release** → selecione o arquivo.

## 6. Testar no Celular
1. USB debugging on
2. Godot: **Projeto → Exportar → Android → Depurar**
3. Jogue!

## 7. Build para Play Store
**Exportar → Android → Release → Exporta .aab** → Upload no Play Console

---

## 📱 O que já funciona:
✅ Jogo completo (puzzle, combo, power-ups, levels)
✅ 4 menus (Main, Shop, Leaderboard, Settings)
✅ Sistema de moedas, vidas, XP, ligas
✅ Daily reward + streak + notificações
✅ IAP (assinatura + consumíveis + permanentes)
✅ Ads (interstitial, rewarded, banner, app open)
✅ Leaderboards + Achievements (Google Play Games)
✅ Save/Load automático
✅ Audio manager + settings

## 🎨 Assets que PRECISA fazer/substituir:
- `assets/ui/icon.png` (512x512) - ícone da loja
- `assets/ui/feature_graphic.png` (1024x500) - banner da loja
- 4 powerup icons (128x128)
- 7 league icons (64x64)
- 2 músicas + 11 SFX (OGG)

Use: **kenney.nl** (grátis) ou **Midjourney/DALL-E** (IA)

---

## 💡 Primeira execução
O jogo dá **500 moedas grátis** no primeiro lançamento para o jogador testar a loja.

---

**Leia o README.md completo para detalhes de publicação, checklist Play Store e estimativa de receita.**