class Porkchop : DMDMonster replaces Fatso {
    // A big ol' piggy who's in the mood for sandwiches.
    // Oh shit, get the fuck outta there--
    // 1. His smog launchers fire canisters that douse an area in oily smog. 
    // Smog can be ignited by AoE damage, causing it to deal AoE damage over a short while.
    // 2. He can ignite that smog with an exploding, bouncing fireball attack.
    // This fireball does 64 damage in a 64-unit AoE.
    // Fun fact: that's a max-damage mancubus fireball! And he fires 3 in a spread.

    int smogshots;

    default {
        Health 500; // Slightly less tanky than the original.
        Radius 48; // Just as big, though.
        Height 48; // Quadrupeds are shorter.
        Mass 700; // Relatively light-weight.
        Speed 6; // Slower.
        PainChance 100; // Like most of these monsters, tends to flinch more.
        +BOSSDEATH; // Gotta have vanilla map compat.
        SeeSound "PPork/See";
        ActiveSound "PPork/Act";
        PainSound "PPork/Pai";
        DeathSound "PPork/Ded";
        Obituary "%o was incinerated by a Porkchop.";
        DropItem "HealthBonus";
        DropItem "HealthBonus";
        DropItem "HealthBonus";
    }

    override State ChooseAttack() {
        // Each time it fires a smog round, the smog round chance gets lower.
        if (random(-3,3) > smogshots) {
            return ResolveState("SmogShot");
        } else {
            return ResolveState("FireShot");
        }
    }

    void FireSmog() {
        A_StartSound("PPork/Launch");
        Shoot("SmogCanister",40,aoffs:(0,30));
    }

    void FireBallSides() {
        A_StartSound("weapons/rocklf");
        Shoot("PorkFireBall",20,aoffs:(45,15));
        Shoot("PorkFireBall",20,aoffs:(-45,15));
    }

    void FireBallMid() {
        A_StartSound("weapons/rocklf");
        Shoot("PorkFireBall",20,aoffs:(20,15));
        Shoot("PorkFireBall",20,aoffs:(-20,15));
    }

    states {
        Spawn:
            PPRK AB Random(6,12) A_Look();
            Loop;
        
        See:
            PPRK ABCD 3 A_Chase();
            Loop;
        
        Missile:
            PPRK E 4 StartAttack();
            Goto See;

        SmogShot:
            PPRK E 5 Aim();
            PPRK E 10 A_StartSound("PPork/See");
            PPRK F 4 FireSmog(); // TODO: actual shot
            PPRK E 8 EndAttack();
            Goto See;
        
        FireShot:
            PPRK E 2 A_StartSound("PPork/Pai");
            PPRK EEE 5 Aim();
            PPRK F 3 FireBallSides(); // TODO: actual shot
            PPRK E 15;
            PPRK F 3 FireBallMid(); // TODO: actual shot
            PPRK E 8 EndAttack();
            Goto See;
        
        Pain:
            PPRK G 8 A_Pain();
            PPRK E 4 EndAttack();
            Goto See;
        
        Death:
            PPRK G 6 A_Pain();
            PPRK H 5 A_Scream();
            PPRK I 5 A_NoBlocking();
            PPRK JKLM 4;
            PPRK M -1;
            Stop;
    }
}

class PorkFireball : Actor {
    // Bouncy exploding projectile.
    default {
        PROJECTILE;
        // DamageFunction (20);
        -NOGRAVITY;
        BounceType "Hexen";
        BounceFactor .8; // Bounces for a while, but not forever!
        BounceCount 8;
        DeathSound "fatso/shotx";
    }

    states {
        Spawn:
            FYRE AB 3 Bright A_SpawnItem("PorkFireTrail");
            Loop;
        Death:
            FIRE A 3 Bright A_Explode(64,64,damagetype:"Fire");
            FIRE BCDEFGH 3 Bright;
            TNT1 A -1;
            Stop;
    }
}

class PorkFireTrail : Actor {
    // Fancy!
    default {
        +NOINTERACTION;
    }

    states {
        Spawn:
            FYRE AB 4 A_FadeOut();
            Loop;
    }
}

class SmogCanister : Actor {
    // Spits out smog until it takes enough damage to explode.
    double smogangle;
    int deathtimer;
    default {
        +SHOOTABLE;
        +NOBLOOD;
        Radius 8;
        Height 12;
        Health 50; 
    }

    void SpawnSmog() {
        double offs = 40;
        double vel = 4;
        smogangle = (smogangle + 10) % 360;
        A_SpawnItemEX("SmogCloud",offs,zofs:offs,xvel:vel,angle:SmogAngle);
        A_SpawnItemEX("SmogCloud",offs,zofs:offs,xvel:vel,angle:SmogAngle+180);
    }

    state FireDeath() {
        A_Explode(5,128,XF_NOTMISSILE,fulldamagedistance:128,damagetype:"Fire");
        A_StartSound("PPork/AirEffect",1,CHANF_NOSTOP);
        deathtimer += 1;
        if (deathtimer > 10) {
            return ResolveState("RealDeath");
        } else {
            return ResolveState(null);
        }
    }

    states {
        Spawn:
            ROCK A 10 SpawnSmog();
            Loop;
        Death:
            ROCK A 5 SpawnSmog();
            ROCK A 0 FireDeath();
            Loop;
        RealDeath:
            MISL B 8 Bright A_StartSound("weapons/rocklx");
            MISL C 7 Bright;
            MISL D 6 Bright;
            TNT1 A -1;
            Stop;
    }
}

class SmogCloud : Actor {
    // Smog clouds ignite if they take damage,
    // but they're non-solid, so AoE weapons are what you need.
    default {
        +SHOOTABLE;
        +NOBLOOD;
        +NOGRAVITY;
        RenderStyle "Translucent";
        Alpha 0.8;
        Health 5;
        Scale 3;
        Radius 64;
        Height 32;
        Obituary "%o was made into Porkchop sandwiches.";
    }

    override int DamageMobj(Actor inf, Actor src, int dmg, Name mod, int flags, double ang) {
        if (flags & DMG_EXPLOSION) {
            return super.DamageMobj(inf,src,dmg,mod,flags,ang);
        } else {
            return 0;
        }
    }

    states {
        Spawn:
            RSMK ABCDE random(2,4) A_FadeOut(0.08);
            Loop;
        Death:
            MISL BCD 6 Bright A_Explode(4,128,XF_NOTMISSILE|XF_EXPLICITDAMAGETYPE,false,128,damagetype:"Fire");
            TNT1 A -1;
            Stop;
    }
}