class FooFighter : DMDMonster replaces Cacodemon {
    // A ball of angry lightning.
    // 1. It spits a stream of plasma, starting low and swinging upward. Each plasma bolt does 15 damage, but there's a *lot* of them.
    // 2. It fires out a lightning orb that travels slowly, periodically spawning additional plasma orbiters. The further this attack travels, the harder it hits!

    Actor coreball;

    default {
        Health 500; // Slightly tankier than usual!
        Radius 30; // Why was it 31 originally?
        Height 56;
        Mass 300;
        Speed 5; // Deceptively fast.
        PainChance 128;
        +FLOAT;
        +NOGRAVITY;
        +DONTFALL;
        +BRIGHT;
        SeeSound "ches/see";
        ActiveSound "ches/act";
    }

    void FirePro() {
        A_StartSound("ChesHit");
        Shoot("FooProliferator",10);
    }

    void FireBeam() {
        A_StartSound("ChesFire");
        Shoot("FooBeam",20);
    }

    void ThrowSparks() {
        A_StartSound("ChesFlame");
        A_SpawnItemEX("FooSparkle",48,xvel:frandom(1,6),zvel:frandom(-6,6),angle:frandom(-30,30));
        // TODO: Spawn little sparklies.
    }

    void ThrowFlames() {
        A_SpawnItemEX("FooFire",48,xvel:frandom(1,2),zvel:frandom(0,3),angle:frandom(0,360));
        // TODO: Spawn little sparklies.
    }


    void StartGhost() {
        bTHRUACTORS = true;
        speed = 10;
        if (coreball) {
            coreball.A_SetRenderStyle(0.0,STYLE_Add);
        }
    }

    void EndGhost() {
        bTHRUACTORS = false;
        speed = 5;
        if (coreball) {
            coreball.A_SetRenderStyle(1.0,STYLE_Add);
        }
    }

    override State ChooseAttack() {
        int roll = random(0,Vec3To(target).length());
        if (roll > 256) {
            return ResolveState("Proliferation");
        } else {
            return ResolveState("Beam");
        }
    }

    override void PostBeginPlay() {
        super.PostBeginPlay();
        coreball = Spawn("FooCore",pos);
    }

    override void Tick() {
        super.Tick();
        if (coreball) {
            coreball.warp(self,-2,heightoffset:0.5);
        }
    }

    override void Die(Actor src, Actor inf, int flags, Name mod) {
        if (coreball) {
            coreball.SetState(coreball.ResolveState("Death"));
        }
        super.Die(src,inf,flags,mod);
    }

    states {
        Spawn:
            SLPS A 1 A_Look();
            Loop;
        
        See:
            SLPS A 1 A_Chase();
            Loop;
        
        Missile:
            SLPS B 1 StartAttack();
            SLPS B 4 A_StartSound("ches/see");
            Goto See;
        
        Proliferation:
            SLPS B 10 Aim();
            SLPS CCCCC 2 ThrowSparks();
            SLPS D 10 FirePro();
            SLPS C 10;
            SLPS B 10 EndAttack();
            Goto See;

        Beam:
            SLPS B 5 Aim(0,270);
            SLPS C 0 { invoker.pitch = 90; }
            SLPS CCCCC 2 ThrowSparks();
        BeamLoop:
            SLPS D 1 FireBeam();
            SLPS C 1 ThrowSparks();
            SLPS B 0 { invoker.pitch -= (invoker.pitch / 6); }
            SLPS B 0 A_JumpIf(invoker.pitch <= 1, "BeamEnd");
            Loop;
        BeamEnd:
            SLPS BBBBB 3 ThrowSparks();
            SLPS A 10 EndAttack();
            Goto See;
        
        Pain:
            SLPS D 4;
            SHSR B 4;
            SLPS D 3;
            SHSR C 3;
            SLPS D 2;
            SHSR D 2;
            SLPS D 2;
            SHSR D 2;
            SLPS D 2 EndAttack();
            Goto Teleport;
        
        Teleport:
            TNT1 A 0 StartGhost();
        TeleLoop:
            TNT1 AAAAA 1 A_Wander();
            TNT1 A 0 A_JumpIf(frandom(0,1) <= .15,"TeleEnd");
            Loop;
        TeleEnd:
            TNT1 A 0 EndGhost();
            Goto See;

        Death:
            SLPS A 0 A_StartSound("chesact3");
            SLPS DDDD 2 ThrowFlames();
            SHSR BBBB 2 ThrowFlames();
            SLPS DDDD 2 ThrowFlames();
            SHSR BBBB 2 ThrowFlames();
            SLPS DDD 2 ThrowFlames();
            SHSR CCC 2 ThrowFlames();
            SLPS DD 2 ThrowFlames();
            SHSR DD 2 ThrowFlames();
            SLPS DD 2 ThrowFlames();
            SHSR DD 2 ThrowFlames();
            SLPS DD 2 ThrowFlames();
            SHSR D 2 A_NoBlocking();
            WARP ABCDEFG 3;
            TNT1 A 0;
            Stop;

    }
}

class FooSparkle : Actor {
    // Bits of purple.
    default {
        +NOINTERACTION;
        +BRIGHT;
        RenderStyle "Add";
    }

    states {
        Spawn:
            FALL ABCDEFGHIJKLMNOP 2;
            TNT1 A 0;
            Stop;
    }
}

class FooFire : FooSparkle {
    default {
        RenderStyle "Normal";
    }
    states {
        Spawn:
            CHFR ABCDEFGHIJKLMNOP 3;
            TNT1 A 0;
            Stop;
    }
}

class FooCore : Actor {
    // Glowy ball of lightning.
    default {
        +NOINTERACTION;
        +BRIGHT;
        RenderStyle "Add";
        Scale 3;
    }

    states {
        Spawn:
            BAL2 AB 4;
            Loop;
        Death:
            BAL2 CDE 5;
            TNT1 A 0;
            Stop;
    }
}

class FooBeam : Actor {
    // A low-damage projectile, but there's a lot of them...
    mixin Shooter;
    default {
        Projectile;
        +BRIGHT;
        DamageFunction (10);
        Obituary "%o let a foo fighter get the best of %h.";
    }

    void SpawnSparks() {
        int age = GetAge();
        double x = sin(age) * 5;
        double y = cos(age) * 5;
        Shoot("FooSparkle",-5,aoffs:(x,y));
        Shoot("FooSparkle",-5,aoffs:(-x,-y));
        A_StartSound("ChesFlame");
    }

    states {
        Spawn:
            SHST AB 3;
            SHST C 3 SpawnSparks();
            Loop;
        Death:
            SHST GHIJKL 3;
            TNT1 A 0;
            Stop;
    }
}

class FooProliferator : Actor {
    // Does little damage by itself...too bad it summons a cloud of bolts.
    mixin Shooter;

    double adds;
    
    default {
        Projectile;
        DamageFunction (5);
        RenderStyle "Add";
        +BRIGHT;
        Obituary "%o was fried from an everlong way away.";
    }

    void SpawnAdd() {
        float range = 3 + adds;
        Vector2 offs = (frandom(-range,range),frandom(-range,range));
        Vector2 angles = (frandom(-5,5),frandom(-5,5));
        double spd = frandom(4,6);
        Shoot("FooAdd",spd,aoffs:angles,poffs:offs);
        Shoot("FooSparkle",-spd,aoffs:angles,poffs:offs);
        adds += 0.3;
    }

    states {
        Spawn:
            BAL2 AB 4;
            BAL2 B 0 SpawnAdd();
            Loop;
        Death:
            BAL2 CDE 5;
            TNT1 A 0;
            Stop;
    }
}

class FooAdd : FooProliferator {
    // Just like FooProliferator, but without proliferation.
    states {
        Spawn:
            BAL2 AB 4;
            Loop;
    }
}