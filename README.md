# SWX2

**Emulador de PlayStation 2 para Windows · PlayStation 2 emulator for Windows**

![Ícone SW do SWX2](resources/icons/AppIconLarge.png)

[Português](#português) · [English](#english)

## Português

### O que é o SWX2?

O **SWX2** é uma distribuição personalizada do emulador **PCSX2**, preparada para executar jogos de **PlayStation 2 (PS2) no Windows**. O projeto reúne o emulador, suas bibliotecas e recursos em uma pasta, com identidade visual própria e uma interface para organizar e iniciar os jogos.

A emulação reproduz por software o funcionamento do console. Assim, o computador pode executar jogos de PS2 usando uma BIOS compatível e imagens dos discos. A compatibilidade, a qualidade gráfica e a velocidade variam conforme o jogo, o hardware e as configurações utilizadas.

Este repositório contém o **pacote executável do SWX2 para Windows**, incluindo arquivos de configuração e recursos. O motor de emulação é baseado no PCSX2; o SWX2 não é um emulador desenvolvido do zero.

### Recursos

- **Biblioteca de jogos:** navegação em lista ou grade, com suporte a capas.
- **Imagens de disco:** uso de formatos como `.iso`, `.chd`, `.cso` e `.bin`.
- **Controles:** suporte a gamepads e configuração dos botões.
- **Memória dos jogos:** cartões de memória virtuais para os saves do próprio jogo.
- **Estados salvos:** possibilidade de salvar e restaurar o estado da emulação, além dos saves tradicionais.
- **Ajustes gráficos:** opções de renderização e resolução, conforme o suporte do computador e do jogo.
- **Tela cheia:** alternativa à interface em janela.
- **Identidade visual SW:** ícone próprio e recursos visuais personalizados.

### Como começar

1. Mantenha o conteúdo do pacote na mesma pasta. O executável depende das bibliotecas e dos recursos que o acompanham.
2. Coloque a BIOS extraída do seu PS2 na pasta `bios/`. Nas configurações do emulador, confira se a pasta de BIOS aponta para esse local e selecione uma BIOS válida.
3. Coloque as imagens dos seus jogos na pasta `jogos/`. Confira se essa pasta está incluída nos diretórios da biblioteca e atualize a lista quando necessário.
4. Abra `SWX2.exe`.
5. Conecte um controle e confira o mapeamento dos botões. O pacote foi preparado para configuração automática na porta 1, mas alguns controles podem exigir ajustes.
6. Selecione um jogo na biblioteca para iniciar.

**Capas:** clique com o botão direito no jogo e use a opção **Definir imagem de capa**.

Se o pacote for movido para outro computador ou pasta, revise os caminhos da BIOS e dos jogos: configurações existentes podem apontar para locais da instalação anterior.

### Organização das pastas

| Arquivo ou pasta | Finalidade |
| --- | --- |
| `SWX2.exe` | Executável principal do emulador. |
| `bios/` | Pasta destinada à BIOS do console. |
| `jogos/` | Pasta destinada às imagens dos jogos. |
| `dados/` | Configurações, saves, cartões de memória, capas, estados salvos e outros dados do usuário. |
| `resources/` | Ícones, fontes, shaders e outros recursos do aplicativo. |
| `QtPlugins/` | Plugins usados pela interface gráfica. |
| `translations/` | Arquivos de tradução da interface. |
| `licencas/` | Licença GPL e avisos dos componentes de terceiros. |

**Faça backup de `dados/` antes de atualizar ou substituir o pacote.** Essa pasta pode conter o progresso dos seus jogos. Os arquivos `.dll` da pasta principal também fazem parte do aplicativo e devem acompanhar o executável.

### Compatibilidade e desempenho

É necessário um computador com Windows compatível com o executável e com as bibliotecas incluídas, além de drivers gráficos adequados. Não há uma configuração de hardware que garanta o mesmo desempenho em todos os jogos.

Resoluções internas maiores e melhorias gráficas podem aumentar a exigência de processamento. Se um jogo apresentar lentidão ou falhas visuais, revise as opções gráficas e os ajustes específicos desse jogo. Estados salvos podem ter limitações de compatibilidade entre versões; mantenha também saves nos cartões de memória virtuais.

### Créditos e licenças

O SWX2 é baseado no trabalho do projeto **PCSX2**, distribuído sob a **GNU GPL v3**. Os avisos de licença estão em `licencas/GPL.html` e `licencas/ThirdPartyLicenses.html`. A identidade visual personalizada do SWX2 não substitui os créditos do projeto original nem as licenças dos componentes utilizados.

SWX2 não é um produto oficial da Sony. PlayStation e PlayStation 2 são marcas de seus respectivos titulares.

---

## English

### What is SWX2?

**SWX2** is a customized distribution of the **PCSX2** emulator, prepared to run **PlayStation 2 (PS2) games on Windows**. The project brings the emulator, its libraries, and its resources together in one folder, with custom branding and an interface for organizing and launching games.

Emulation recreates the console's operation through software. This allows a computer to run PS2 games using a compatible BIOS and disc images. Compatibility, graphics quality, and speed depend on the game, the hardware, and the selected settings.

This repository contains the **SWX2 executable package for Windows**, including configuration files and resources. Its emulation engine is based on PCSX2; SWX2 is not an emulator written from scratch.

### Features

- **Game library:** browse games in a list or grid, with cover art support.
- **Disc images:** use formats such as `.iso`, `.chd`, `.cso`, and `.bin`.
- **Controllers:** gamepad support and configurable button mappings.
- **Game saves:** virtual memory cards for the games' built-in save systems.
- **Save states:** save and restore the emulation state alongside traditional game saves.
- **Graphics settings:** rendering and resolution options, depending on hardware and game support.
- **Fullscreen mode:** an alternative to the windowed interface.
- **SW branding:** a custom application icon and visual resources.

### Getting started

1. Keep the package contents together in the same folder. The executable depends on the accompanying libraries and resources.
2. Place the BIOS dumped from your PS2 in `bios/`. In the emulator settings, check that the BIOS directory points to this location and select a valid BIOS.
3. Place your game disc images in `jogos/`. Check that this folder is included in the library's game directories and refresh the list when needed.
4. Open `SWX2.exe`.
5. Connect a controller and check its button mappings. The package is prepared for automatic setup on port 1, but some controllers may require adjustments.
6. Select a game from the library to launch it.

**Cover art:** right-click a game and select the option to set its cover image, labeled **Definir imagem de capa** in Portuguese.

If you move the package to another computer or folder, review the BIOS and game paths: existing settings may point to locations from the previous installation.

### Folder structure

| File or folder | Purpose |
| --- | --- |
| `SWX2.exe` | Main emulator executable. |
| `bios/` | Intended location for the console BIOS. |
| `jogos/` | Intended location for game disc images. |
| `dados/` | Settings, game saves, memory cards, cover art, save states, and other user data. |
| `resources/` | Application icons, fonts, shaders, and other resources. |
| `QtPlugins/` | Plugins used by the graphical interface. |
| `translations/` | Interface translation files. |
| `licencas/` | GPL license and third-party notices. |

**Back up `dados/` before updating or replacing the package.** This folder may contain your game progress. The `.dll` files in the main folder are also part of the application and must stay with the executable.

### Compatibility and performance

You need a Windows computer compatible with the executable and its included libraries, along with suitable graphics drivers. No single hardware configuration guarantees the same performance in every game.

Higher internal resolutions and graphics enhancements can increase processing demands. If a game runs slowly or displays visual glitches, review its graphics options and game-specific settings. Save states may have compatibility limitations across versions; keep regular saves on virtual memory cards as well.

### Credits and licenses

SWX2 is based on the work of the **PCSX2** project, distributed under the **GNU GPL v3**. License notices are available in `licencas/GPL.html` and `licencas/ThirdPartyLicenses.html`. SWX2's custom branding does not replace the original project's credits or the licenses of its components.

SWX2 is not an official Sony product. PlayStation and PlayStation 2 are trademarks of their respective owners.
