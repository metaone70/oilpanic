# Oil Panic
Oil Panic for the Commodore 64

https://metesev.itch.io/oil-panic

Step into the shoes of the hardest-working Service Attendant in the 8-bit world. 
In this faithful C64 tribute to the dual-screen LCD classics, your mission is simple: 
Catch the oil. Fill the drum. Don't soak the customers.

Development Period: February 2nd – February 19th, 2026

The Toolkit

To bring this retro experience to life, I utilized a specialized suite of modern and classic tools:

Programming: Written in Assembly using Visual Studio Code + Kick Assembler (8-Bit Retro Studio extension).

Environment: Tested via VICE64 v3.10 and Commodore 128 in C64 mode, fine-tuned with C64Debugger.
Art Assets:

Main Screen: Crafted in Multipaint (Bitmap Mode).

Intro/Menu: Designed using Charpad Pro.

Animation: Sprites handled via SpritePad Pro.

Audio: Soundtrack composed in Goattracker v2.76.

Research: Gameplay dynamics verified via DeSmuME to ensure mechanical accuracy.

DEVELOPMENT LOG

//v1 & v2 bitmap graphics and sprites have been drawn (02-03.02.2026)
//v3 (04.02.2026)
// Using raster split, the 1st and 2nd sprites have been reused on the 
// bottom of the screen.
//v4 (04.02.2026)
// Sprites are being designed during this period. Due to the amount of sprites, 
// the base memory has been declared as $4800. 
// Also, the first sprite is reserved for score table. The score digits are converted to 
// single sprite and then combined by necessary number sprites from font library.
// After 999, it reverts back to 0.
//v5 (06.02.2026)
// In the score, now zero values in the tens and huns don't show.
// Sprite design stage has been completed. Sprite animation pointers have been added but to be checked.
// Sprite base address moved to $4c00.
//v6 (08.02.2026)
// An intro screen is added. A screen prepared in CharPad is accompanied with music 
// and scrolling text.
//v7 (08.02.2026)
// Addresses used for intro map etc. have been reorganized.
// Intro screen (in intro.asm) has been re-written. A text info screen has been added. 
// Also new key assignment routine has been included.
//v8 (09.02.2026)
// & sign has been fixed in intro screen. Top and bottom bars have been drawn in the text screen.
// Bitmap screen now has "Game A & B" buttons
// Game type selection, new key selection and start buttons are programmed on function keys in intro.asm
// Now game type is correctly shown on the game (bitmap) screen
//v9 (10.02.2026)
// Control keys have been changed to Z and M.
// Oil drop pattern has been written (not fully implemented)
// Collector moving routine has been written for both game modes (B is slightly faster)
//V10 (10.02.2026)
// Oil drop routine implemented
//v11 (11.02.2026)
// Oil drop delay routine implemented for both game modes
// Music has been relocated from $c400 to $9400 
// Top screen player routine implemented. Oil drops also fill the bucket.
//v12 (11.02.2026)
// Oild drops and the player routines have been rewritten (flicker and garbage sprites eliminated)
// Now the player can catch the drops and gets the point. 
//v13 (12.02.2026)
// Player on the bottom screen is active now. Also scoring algorith is revised.
// During pouring, the digits can been seen incrementing.
//v14 (14.02.2026)
// Bottom misses lives have been added. Collector at the bottom now waits while the bucket is emptied.
//v15 (14.02.2026)
// Animation for bottom oil drop emptying has been added (sprites updated).
// At the "main" section, randmoization of drop spawn at the beginning of the game has been added.
// Animation of top fires have been added.
//v16 (14.02.2026)
// Both lady and gent animation have been added.
// v17 (14.02.2026)
// The speed of oils dripping now is increase at every 100 points (upto 500) and stays there.
// During lady and gent animation, now the player cannot play, oil does not spawn, and collector does not move.
//v18 (14.02.2026)
// Bonus section added. Any time in the game, after 300 points without a miss causes bonus stage, where
// the collector is doubled on the edges and also points for pouring are also doubled for around 30 seconds.
//V19 (14.02.2026)
// The ending routine has been established. Game Over sprite is written, and if there is a high score
// a High Score sprite flashes and returns back to the info text screen.
//v20 (15.02.2026)
// Sound effets for drops and misses have been added. Some timings were also finetuned.
// Intro screen has been changed to a new one (with red circular oil panic text).
// Intro text screen has been colored.
// Now the left/right keys are reflected to the screen together with the changes.
// Game code is between $0800-$9a3a (37.434 bytes - 36k)
//v21 (15.02.2026)
// The speed increase has been adjusted to work at even hundreds (200-400-600-800).
// The music has been relocated. I can't find the original .sng file for Goattracker but I have the
// SID file. I relocated it using SIDRELOC to $3000, and using Kickassembler's Loadsid command
// I could play it in the game. Since I moved the sonf from $9400 to $3000, the 3K at the end of
// the program freed, so now the  game is shorter. Some polishing in the lady/gent animation.
// The drop spawn pattern is increased to 15 steps to balance the patterns.
// Intro & game screens have been altered for any possible copyright claims from Nintendo.
// As mentioned now, this is a non-profit fan-made game.
//v22 (17.02.2026)
// New music has been written in Goattracker (shikata).
// Some minor tweaks done, some unused variables removed.
//v23 (18.02.206)
// Testing and some minor tweaks.
//v24
// Testing and collector speed table update. Now the collector also gets a speed increase.
// I'm not sure how I missed that before.
// Now misses will be cleared when entering the bonus stage.
// High score is now shown on the info text screen. If resetted the game after 999
// the high score will alway show 999.
