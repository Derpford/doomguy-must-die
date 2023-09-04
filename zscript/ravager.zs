class HellRavager : DMDMonster replaces HellKnight {
    // You are rage, brutal, without mercy. Against you, Hell sends many horrors, but this warrior is one of the most dangerous.
    // 1. The Ravager raises his shield, gaining 50% DR. After taking 100 damage in this state, the shield fires a counterattack beam cannon; each segment of the Green Beam does 20 damage.
    // 2. The Ravager can also lunge forward and throw a spread of 5 fireballs, which decelerate over time and then disappear. Each one does 50 damage.
    // It alternates between these attacks.

    bool shieldnext; // when true, next attack is shield; if false, next attack is fireballs
    int shieldtimer; // How long until the shield stops?
    int dmgbuffer; // How much damage have we stocked for the beam cannon?

    default {
        Health 500;
        Radius 24;
        Height 64;
        Mass 1000;
        Speed 8;
        PainChance 32; // Harder to flinch.
        SeeSound "knight/sight";
		ActiveSound "knight/active";
		PainSound "knight/pain";
		DeathSound "knight/death";
    }

    override int DamageMobj(Actor inf, Actor src, int dmg, name mod, int flags, double angle) {
        if (CountInv("RavShield") > 0) {
            dmgbuffer += dmg;
        }

        return super.DamageMobj(inf,src,dmg,mod,flags,angle);
    }

    override State ChooseAttack() {
        if (shieldnext) {
            shieldnext = false;
            return ResolveState("Shield");
        } else {
            shieldnext = true;
            return ResolveState("Balls");
        }
    }

    void StartShield() {
        shieldtimer = 35;
        bNOPAIN = true;
        GiveInventory("RavShield",1);
    }

    state HoldShield() {
        shieldtimer -= 1;
        Aim(10,5);
        if (dmgbuffer >= 100) {
            return ResolveState("Beam");
        } else if (shieldtimer <= 0) {
            return ResolveState("ShieldEnd"); 
        }
        return ResolveState(null);
    }

    void EndShield() {
        bNOPAIN = false;
        TakeInventory("RavShield",1);
        shieldtimer = 0;
    }

    void FireBeam() {
        A_StartSound("weapons/plasmaf");
        dmgbuffer -= 10;
        Shoot("RavBeam",20);
    }

    void ThrowShield() {
        A_SpawnItemEX("DroppedShield",yofs:-32,yvel:frandom(-4,-8),zvel:frandom(6,12));
    }

    state BeamCheck() {
        if (dmgbuffer <= 0) {
            return ResolveState("Shield"); // Triggering a beam counter resets the shield!
        } else {
            return ResolveState(null);
        }
    }

    void FireBalls() {
        // TODO: Spread of fireballs
        A_StartSound("baron/attack");
        double spread = 10;
        for (int i = -2; i < 3; i++) {
            Shoot("RavBall",10,aoffs:(i*spread,0));
        }
    }

    states {
        Spawn:
            HWAR AB Random(4,8) A_Look();
            Loop;
        
        See:
            HWAR ABCD 4 A_Move();
            Loop;
        
        Missile:
            HWAR G 8 StartAttack();
            HWAR J 8;
            Goto See;
        
        Shield:
            HWAR H 1 StartShield();
        ShieldLoop:
            HWAR H 1 HoldShield();
            Loop;
        ShieldEnd:
            HWAR F 4 EndShield();
            HWAR G 6 EndAttack();
            HWAR G 6 A_StartSound("knight/pain");
            Goto See;
        
        Beam:
            HWAR H 3 A_Pain();
            HWAR IHIHIH 3;
        BeamLoop:
            HWAR I 1 FireBeam();
            HWAR H 1 Aim(20,10);
            HWAR H 0 BeamCheck();
            Loop; 

        Balls:
            HWAR E 5 Aim();
            HWAR E 5 Thrust(16,angle);
            HWAR F 4;
            HWAR G 6 FireBalls();
            HWAR G 10 EndAttack();
            Goto See;
        
        Pain:
            HWAR J 8 A_Pain();
            HWAR K 4 EndAttack();
            HWAR J 4;
            Goto See;
        
        Death:
            HWAR J 8 A_Pain();
            HWAR K 5;
            HWAR L 5 ThrowShield();
            HWAR M 5 A_Scream();
            HWAR NO 5;
            HWAR P 5 A_NoBlocking();
            HWAR QRST 5;
            HWAR T -1;
            Stop;
    }
}

class RavShield : Inventory {
    // Literally just grants 50% DR while in inventory.

    override void ModifyDamage(int dmg, Name mod, out int new, bool passive, Actor inf, Actor src, int flags) {
        if (passive) {
            new = dmg / 2;
        }
    }
}

class RavBall : Actor {
    // Great balls o' fire!

    default {
        Projectile;
        +BRIGHT;
        RenderStyle "Add";
        DamageFunction (0);
    }

    state BallMove() {
        double spd = vel.length() - 1;
        if (spd > 0) {
            vel = vel.unit() * spd;
            return ResolveState(null);
        } else {
            return ResolveState("Death");
        }
    }

    states {
        Spawn:
            HWFB AB 5 BallMove();
            loop;
        
        Death:
            HWFB C 3 A_StartSound("baron/shotx");
            HWFB C 2 A_Explode(50);
            HWFB DE 5;
            TNT1 A 0;
            Stop;
    }
}

class RavBeam : Actor {
    // Mean Green Beam.
    default {
        Projectile;
        +BRIGHT;
        DamageFunction (20);
        RenderStyle "Add";
    }

    states {
        Spawn:
            GRBA ABCDEFGH 2;
            Loop;

        Death:
            GRBA I 2 A_StartSound("baron/shotx");
            GRBA JKLM 2;
            TNT1 A 0;
            Stop;
    }
}

class DroppedShield : Actor {
    // Oops.
    mixin FallingDebris;
    override void Tick() {
        super.Tick();
        ProcessFall();
    }

    states {
        Spawn:
            HWSH ABCDEFGH 3;
            Loop;
        
        Crash:
            HWSH I -1;
            Stop;
    }
}

class HellDestroyer : HellRavager replaces BaronOfHell {
    // A cybernetically-upgraded Hell Ravager.
    // 1. The shield returns, this time with an explosive counter. The 3 projectiles do 60 splash damage.
    // 2. The Hell Destroyer retains the spread of decelerating fireballs, but this time he follows it up with a rocket-propelled grenade that does 80 splash damage.

    default {
        Health 1000;
        +BOSSDEATH;
    }

    void StartShield() {
        shieldtimer = 5; // Comes out to slightly longer than the Ravager's.
        bNOPAIN = true;
        GiveInventory("RavShield",1);
    }

    state ChaseShield() {
        A_Chase(null,null);
        return super.HoldShield();
    }

    void FireMissile() {
        A_StartSound("Paladin/Grenade");
        Shoot("DestroyerMissile",30);
    }

    void FireBalls() {
        A_StartSound("baron/attack");
        double spread = 15;
        for (int i = -2; i < 3; i++) {
            Shoot("RavBall",6,aoffs:(i*spread,0));
        }
    }

    void FireBlasts() {
        A_StartSound("Paladin/Shoot");
        dmgbuffer -= 100;
        for (int i = -1; i < 2; i++) {
            Shoot("DestroyerBlast",20,aoffs:(i*30,0));
        }
    }

    states {
        Spawn:
            HPAL AB Random(4,6) A_Look();
            Loop;
        
        See:
            HPAL ABCD 4 A_Move();
            Loop;
        
        Missile:
            HPAL K 8 StartAttack();
            HPAL K 8;
            Goto See;
        
        Shield:
            HPAL E 0 Aim();
            HPAL E 1 StartShield();
        ShieldLoop:
            HPAL EFGH 8 ChaseShield();
            Loop;
        ShieldEnd:
            HPAL M 4 EndShield();
            HPAL N 6 EndAttack();
            HPAL O 6 A_StartSound("knight/pain");
            Goto See;
        
        Beam:
            HPAL K 3 A_Pain();
            HPAL LKLKLK 3 Aim(15,10);
        BeamLoop:
            HPAL L 5 FireBlasts();
            HPAL K 10;
            Goto Shield;

        Balls:
            HPAL I 10 Aim();
            HPAL I 4;
            HPAL J 6 FireBalls();
            HPAL I 4;
            HPAL J 6 FireMissile();
            HPAL I 10 EndAttack();
            Goto See;
        
        Pain:
            HPAL P 8 A_Pain();
            HPAL Q 4 EndAttack();
            HPAL P 4;
            Goto See;
        
        Death:
            HPAL P 8 A_Pain();
            HPAL Q 5;
            HPAL R 5 ThrowShield();
            HPAL S 5 A_Scream();
            HPAL TU 5;
            HPAL V 5 A_NoBlocking();
            HPAL W 0 A_BossDeath();
            HPAL W -1;
            Stop;
    }
}

class DestroyerMissile : Actor {
    // Explosive!
    default {
        Projectile;
    }

    states {
        Spawn:
            PGRN A 1;
            Loop;
        
        Death:
            PGRN A 0 A_StartSound("Paladin/Explode");
            MISL B 4 Bright A_Explode(80,flags:0);
            MISL CD 4 Bright;
            TNT1 A 0;
            Stop;
    }
}

class DestroyerBlast : Actor {
    // Less explosive.
    default {
        +BRIGHT;
        Projectile;
        RenderStyle "Add";
    }

    states {
        Spawn:
            HPLB ABCD 3;
            Loop;
        
        Death:
            HPLB E 3 A_StartSound("Paladin/Hit");
            HPLB F 3 A_Explode(60,flags:0);
            HPLB GHIJKLMNOP 3;
            TNT1 A 0;
            Stop;
    }
}