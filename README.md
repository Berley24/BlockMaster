# Block Master - Puzzle Game for Play Store

Jogo de puzzle viciante estilo Tetris + 2048 + Match-3 com monetização completa.

## 🎮 Funcionalidades do Jogo

### Core Gameplay
- **Grade 10x10** - Arraste blocos para completar linhas/colunas
- **Sistema de Combo** - Multiplicador de pontuação até 5x
- **Power-ups** - Bomba, Embaralhar, Desfazer, Limpar Cor
- **Níveis infinitos** - Progressão com XP e recompensas
- **Ligas competitivas** - Bronze → Prata → Ouro → Platina → Diamante → Mestre → Grão-Mestre

### Monetização (Como você pediu)
| Item | Preço | Tipo |
|------|-------|------|
| Remover anúncios (1 mês) | R$ 14,99 | Assinatura |
| Remover anúncios (vitalício) | R$ 9,99 | Compra única |
| 100 Moedas | R$ 4,99 | Consumível |
| 500 Moedas (+10%) | R$ 19,99 | Consumível |
| 1.200 Moedas (+16%) | R$ 44,99 | Consumível |
| 2.500 Moedas (+20%) | R$ 89,99 | Consumível |
| Power-ups permanentes | R$ 3,99 - 11,99 | Desbloqueio |
| Vidas extras | 50-200 moedas | In-game |
| Continue (reviver) | 100 moedas / 1 vida / anúncio | In-game |

### Anúncios
- **Interstitial**: A cada 3-4 game overs
- **Rewarded**: Continue grátis, moedas bônus, power-ups
- **Banner**: Na loja e menus (não durante gameplay)
- **App Open**: Ao abrir o app

### Retenção & Competição
- **Recompensa diária** - Moedas + vidas, streak de 30 dias
- **Torneio semanal** - Ranking resetado toda segunda
- **Leaderboards** - Global, Semanal, Diário, Amigos
- **Conquistas** - 12 achievements no Google Play Games
- **Notificações push** - Lembretes inteligentes

## 🛠 Setup do Projeto

### 1. Pré-requisitos
- **Godot 4.2+** (versão estável)
- **Android SDK** (API 24+)
- **JDK 17+**
- **Conta Google Play Console** ($25 taxa única)

### 2. Abrir no Godot
```
1. Abra o Godot 4
2. Clique em "Importar"
3. Selecione a pasta BlockMaster
4. Clique em "Importar e Editar"
```

### 3. Configurar Plugins (Obrigatório para Android)

#### GodotPayment (IAP)
```
1. Baixe: https://github.com/godotengine/godot-payment-plugin
2. Extraia em: BlockMaster/addons/godotpayment/
3. No Godot: Projeto > Plugins > Ative "GodotPayment"
```

#### GodotAdMob (Anúncios)
```
1. Baixe: https://github.com/godotengine/godot-admob-plugin
2. Extraia em: BlockMaster/addons/godotadmob/
3. No Godot: Projeto > Plugins > Ative "GodotAdMob"
```

#### GodotPlayGamesServices (Leaderboards)
```
1. Baixe: https://github.com/godotengine/godot-play-games-services
2. Extraia em: BlockMaster/addons/godotplaygamesservices/
3. No Godot: Projeto > Plugins > Ative "GodotPlayGamesServices"
```

#### GodotNotifications (Push)
```
1. Baixe: https://github.com/godotengine/godot-notifications
2. Extraia em: BlockMaster/addons/godotnotifications/
3. No Godot: Projeto > Plugins > Ative "GodotNotifications"
```

### 4. Configurar IDs do Google Play

Edite `scripts/autoload/MonetizationManager.gd`:
```gdscript
const AD_UNITS = {
    "interstitial": "ca-app-pub-SEU_ID_AQUI/SEU_ID_INTERSTITIAL",
    "rewarded": "ca-app-pub-SEU_ID_AQUI/SEU_ID_REWARDED",
    "banner": "ca-app-pub-SEU_ID_AQUI/SEU_ID_BANNER",
    "app_open": "ca-app-pub-SEU_ID_AQUI/SEU_ID_APP_OPEN"
}
```

Edite `scripts/autoload/LeaderboardManager.gd`:
```gdscript
var _leaderboard_id_high_score: String = "SEU_ID_LEADERBOARD_GLOBAL"
var _leaderboard_id_weekly: String = "SEU_ID_LEADERBOARD_SEMANAL"
var _leaderboard_id_daily: String = "SEU_ID_LEADERBOARD_DIARIO"

var _achievements = {
    "first_win": "SEU_ID_ACHIEVEMENT_FIRST_WIN",
    "combo_5": "SEU_ID_ACHIEVEMENT_COMBO_5",
    # ... complete todos os 12
}
```

### 5. Configurar Keystore (Release)

```bash
# Gerar keystore
keytool -genkey -v -keystore release.keystore -alias blockmaster -keyalg RSA -keysize 2048 -validity 10000

# Editar user.properties com suas senhas
storeFile=release.keystore
storePassword=SUA_SENHA
keyAlias=blockmaster
keyPassword=SUA_SENHA
```

No Godot: **Projeto > Exportar > Android > Keystore Release** - selecione o arquivo e preencha as senhas.

### 6. Configurar Package Name
Em `export_presets.cfg`:
```
package_name="com.SEU_NOME.blockmaster"
```

## 🎨 Assets Necessários

Substitua os placeholders em `assets/`:

| Arquivo | Tamanho | Descrição |
|---------|---------|-----------|
| `assets/ui/icon.png` | 512x512 | Ícone do app (Play Store) |
| `assets/ui/feature_graphic.png` | 1024x500 | Banner da Play Store |
| `assets/ui/powerup_bomb.png` | 128x128 | Ícone bomba |
| `assets/ui/powerup_shuffle.png` | 128x128 | Ícone embaralhar |
| `assets/ui/powerup_undo.png` | 128x128 | Ícone desfazer |
| `assets/ui/powerup_colorclear.png` | 128x128 | Ícone limpar cor |
| `assets/ui/league_0.png` a `league_6.png` | 64x64 | Ícones das ligas |
| `assets/audio/music_menu.ogg` | - | Música menu |
| `assets/audio/music_gameplay.ogg` | - | Música jogo |
| `assets/audio/sfx_*.ogg` | - | 11 efeitos sonoros |

**Dica**: Use https://kenney.nl/assets ou https://itch.io/game-assets para assets gratuitos, ou gere com IA (Midjourney, DALL-E).

## 📱 Build para Android

### Debug (teste no celular)
```
1. Conecte o celular via USB (depuração USB ativada)
2. No Godot: Projeto > Exportar > Android > "Exportar Projeto" > "Depurar"
3. Instale o APK no celular
```

### Release (Play Store)
```
1. Projeto > Exportar > Android
2. Selecione "Release" 
3. Keystore: seu release.keystore
4. Clique "Exportar" → gera BlockMaster.aab (App Bundle)
5. Faça upload do .aab no Play Console
```

## 📋 Checklist Play Store

### Obrigatórios
- [ ] Ícone 512x512 (assets/ui/icon.png)
- [ ] Feature Graphic 1024x500
- [ ] 2+ Screenshots telefone (1080x1920)
- [ ] 1+ Screenshot tablet (opcional)
- [ ] Vídeo promo (opcional, 30s)
- [ ] Descrição curta (80 chars)
- [ ] Descrição completa (4000 chars)
- [ ] Política de Privacidade (URL)
- [ ] Classificação etária (questionário IARC)

### Configurações Play Console
- [ ] Produtos IAP criados (mesmos IDs do código)
- [ ] Assinaturas criadas (no_ads_monthly)
- [ ] Leaderboards criados (3 IDs)
- [ ] Conquistas criadas (12 IDs)
- [ ] Testadores internos adicionados
- [ ] Teste fechado → Teste aberto → Produção

### Políticas
- [ ] `privacidade.md` no repo / site
- [ ] Botão "Excluir conta" no app (Settings)
- [ ] Consentimento LGPD/GDPR (first launch)
- [ ] ID de publicidade (AdMob) declarado

## 💰 Estimativa de Receita

### Cenário Conservador (1.000 DAU)
- 2% taxa conversão IAP = 20 compradores/dia
- Ticket médio R$ 15 = R$ 300/dia = **R$ 9.000/mês**
- eCPM anúncios R$ 8 = 1.000 * 4 ads * 30 * 0.008 = **R$ 960/mês**
- **Total: ~R$ 10.000/mês**

### Cenário Otimista (10.000 DAU)
- 3% conversão = 300 compradores/dia
- Ticket médio R$ 20 = R$ 6.000/dia = **R$ 180.000/mês**
- eCPM R$ 12 = 10.000 * 4 * 30 * 0.012 = **R$ 14.400/mês**
- **Total: ~R$ 194.000/mês**

## 🐛 Debug & Testes

### Testar IAP sem publicar
```
1. Play Console > Produtos > "Licenças de teste"
2. Adicione emails de teste
2. No celular: Configurar conta de teste no Play Store
3. Compras serão gratuitas para testadores
```

### Testar Anúncios
```gdscript
# Em MonetizationManager.gd, use IDs de teste do AdMob:
const TEST_AD_UNITS = {
    "interstitial": "ca-app-pub-3940256099942544/1033173712",
    "rewarded": "ca-app-pub-3940256099942544/5224354917",
    "banner": "ca-app-pub-3940256099942544/6300978111",
}
```

### Logs no celular
```bash
adb logcat -s Godot
```

## 🔧 Personalização

### Ajustar Dificuldade
Em `scripts/game/GameScene.gd`:
```gdscript
const LIVES_RECOVERY_TIME = 300  # 5 min por vida
const MAX_COMBO_MULTIPLIER = 5.0
```

### Ajustar Economia
Em `GameManager.gd`:
```gdscript
# Moedas por linha limpa
GameManager.add_coins(lines_cleared_this_turn * 5)

# Recompensa diária base
var reward_coins = 50 + daily_streak * 10
```

### Adicionar Novos Power-ups
1. Adicione em `GameManager.owned_powerups`
2. Crie botão em `GameScene.tscn` (BottomBar)
3. Implemente método `use_novo_powerup()` em `GameScene.gd`
4. Adicione item na Shop

## 📁 Estrutura do Projeto
```
BlockMaster/
├── project.godot
├── export_presets.cfg
├── user.properties
├── README.md
├── addons/
│   ├── godotpayment/
│   ├── godotadmob/
│   ├── godotplaygamesservices/
│   └── godotnotifications/
├── assets/
│   ├── sprites/
│   ├── ui/
│   ├── fonts/
│   └── audio/
├── scenes/
│   ├── game/
│   │   ├── GameScene.tscn
│   │   └── GameScene.gd
│   ├── menus/
│   │   ├── MainMenu.tscn/.gd
│   │   ├── ShopMenu.tscn/.gd
│   │   ├── LeaderboardMenu.tscn/.gd
│   │   └── SettingsMenu.tscn/.gd
│   └── ui/
│       ├── ShopItem.tscn/.gd
│       └── LeaderboardEntry.tscn/.gd
└── scripts/
    ├── autoload/
    │   ├── GameManager.gd
    │   ├── MonetizationManager.gd
    │   ├── SaveManager.gd
    │   ├── LeaderboardManager.gd
    │   ├── AudioManager.gd
    │   └── NotificationManager.gd
    ├── game/
    │   ├── Grid.gd
    │   ├── BlockPreview.gd
    │   └── PowerUpButton.gd
    ├── menus/
    └── ui/
        └── AnimatedButton.gd
```

## 🚀 Próximos Passos Recomendados

1. **Teste local** - Jogue bastante, ajuste difficulty curve
2. **Assets finais** - Contrate artista ou use assets pagos de qualidade
3. **Soft launch** - Brasil/PT primeiro, colete métricas
4. **A/B testing** - Preços, frequência ads, recompensas
5. **LiveOps** - Eventos sazonais, passes de batalha, skins
6. **UA** - TikTok/Reels orgânicos + Ads se CPI < LTV

## 📞 Suporte

- **Godot Docs**: https://docs.godotengine.org
- **Godot Discord**: #android #mobile #monetization
- **Play Console Help**: https://support.google.com/googleplay/android-developer

---

**Boa sorte!** 🎮💰 Qualquer dúvida, é só perguntar.