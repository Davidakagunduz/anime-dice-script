# Anime Dice Script Hub

Script Roblox pour le jeu **Anime Dice**.  
Compatible avec **Delta Executor**, Wave, Solara, Zorara et tout executor Level 7+.

## Fonctionnalités

| Module | Description |
|--------|-------------|
| Auto Roll | Lance les dés automatiquement en boucle |
| Auto Collect | Ramasse les récompenses et items au sol |
| Auto Farm | Farm complet (roll + collect + merge en boucle) |
| Luck Boost | Intercepte les rolls pour favoriser les raretés hautes |
| Speed Boost | Vitesse de déplacement x3 |
| Infinite Jump | Sauter indéfiniment en l'air |
| Player ESP | Voir les joueurs à travers les murs + nametag |
| TP to Spawn | Téléportation instantanée au spawn |
| TP to NPC | Téléportation au PNJ le plus proche |

## Utilisation

### Delta Executor
1. Ouvre Delta Executor
2. Lance Roblox et entre dans Anime Dice
3. Attache Delta au jeu
4. Colle ce script dans l'éditeur :

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/davidakagunduz/anime-dice-script/main/main.lua"))()
```

5. Clique sur **Execute**

### Contrôles en jeu
- Le menu s'affiche automatiquement
- **RightShift** pour afficher / cacher le menu
- Clique sur un toggle pour activer / désactiver un module
- **X** pour réduire la fenêtre

## Note

Le script scanne automatiquement les RemoteEvents du jeu. Si Anime Dice met à jour ses noms de remotes, le script s'adapte grâce à la recherche par pattern.
