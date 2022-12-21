class HunterKiller : DMDMonster replaces Revenant {
    // Missile alert!
    // 1. Fires a series of 4 homing missiles. The missiles are pretty slow...until they get within 256 units of you, at which point they stop tracking and accelerate.
    // Each one does 50 damage on impact. 
    // 2. Sets off a fusilade of teleported explosives, marking a spot somewhere near you. A second or two later, that spot blows the fuck up. 80 splash damage.

    default {
        Health 400; // Slightly tougher than usual, to make up for the lack of melee attack.
        Radius 20;
        Height 56;
        Mass 300; // Featherweight!
        Speed 10; // And much faster, too.
        PainChance 192; // Easier to flinch, because that's the only way to stop one from attacking
        +AVOIDMELEE;
        MeleeRange 256; // Doesn't actually have a melee attack, so this should make +AVOIDMELEE keep this one at 256 units away
        SeeSound "skeleton/sight";
		PainSound "skeleton/pain";
		DeathSound "skeleton/death";
		ActiveSound "skeleton/active";
    }

    override state ChooseAttack() {
        int roll = random(0,max(256, Vec3To(target).length()));

        if (roll < 128) {
            return ResolveState("Artillery");
        } else {
            return ResolveState("Rockets");
        }
    }

    void FireArty() {
        // TODO: Spawn artillery strikes around the player.
        A_StartSound("weapons/rocklf");
        Shoot("RocketExhaust",3);
        target.A_SpawnItemEX("ArtyMarker",frandom(64,256),angle:frandom(0,360));
    }

    void FireRockets() {
        // Fox two!
        A_StartSound("skeleton/attack");
        Actor m1 = Shoot("HomingRocket",10,aoffs:(-20,-30));
        Actor m2 = Shoot("HomingRocket",10,aoffs:(20,-30));
        m1.tracer = target;
        m2.tracer = target;
    }

    states {
        Spawn:
            SKEL AB Random(3,6) A_Look();
            Loop;
        
        See:
            SKEL AABBCCDDEEFF 1 A_Chase();
            Loop;
        
        Missile:
            SKEL K 5 Aim();
            SKEL K 30 StartAttack();
            Loop; // Keeps trying until it gets an attack off!
        
        Rockets:
            SKEL K 10 Aim();
            SKEL J 4 Bright FireRockets();
            SKEL K 6;
            SKEL K 10 EndAttack();
            Goto See;
        
        Artillery:
            SKEL G 5 A_StartSound("skeleton/sight");
            SKEL G 10 Aim(offs:(0,-45));
            SKEL G 3 Bright FireArty();
            SKEL G 2;
            SKEL G 3 Bright FireArty();
            SKEL G 2;
            SKEL G 3 Bright FireArty();
            SKEL G 2;
            SKEL H 5;
            SKEL K 5 EndAttack();
            Goto See;

        Pain:
            SKEL L 5 A_Pain();
            SKEL G 5;
            SKEL H 5;
            SKEL K 5;
            Goto See;
        
        Death:
            SKEL LM 6;
            SKEL N 6 A_Scream();
            SKEL O 6 A_NoBlocking();
            SKEL P 5;
            SKEL Q -1;
            Stop;
    }
}

class HomingRocket : Actor {
    mixin Shooter;
    bool stage; // Is it time to accelerate?
    default {
        Projectile;
        +SEEKERMISSILE;
        DamageFunction (50);
    }

    void Seek() {
        if (tracer && tracer.health > 0 && !stage) {
            double spread = 7.;
            A_StartSound("hk/beep",1,CHANF_NOSTOP);
            // A_SeekerMissile(0,10,SMF_CURSPEED|SMF_PRECISE);
            // SeekerMissile has this annoying habit of not using pitch correctly.
            Vector3 delta = Vec3To(tracer);
            double da = DeltaAngle(angle, AngleTo(tracer));
            double dp = DeltaAngle(pitch,VectorAngle(delta.z+(tracer.height / 2.),(delta.x,delta.y).length())) - 90;
            dp = clamp(dp, -spread,spread);
            da = clamp(da, -spread,spread);
            angle += da;
            pitch += dp;
            Vel3DFromAngle(vel.length(),angle,pitch);
            Shoot("RocketExhaust",-10);
            if (Vec3To(tracer).length() < 192) {
                stage = true;
                A_StopSound(1);
                A_StartSound("fatso/attack");
            }
        } else {
            vel = vel.unit() * (vel.length() + 5);
        }
    }

    states {
        Spawn:
            DART A 3 Seek();
            Loop;
        
        Death:
            FBXP A 0 A_StartSound("skeleton/tracex");
            FBXP ABC 4 Bright;
            TNT1 A 0;
            Stop;
    }
}

class RocketExhaust : Actor {
    default {
        +NOINTERACTION;
        RenderStyle "Add";
        +BRIGHT;
    }

    states {
        Spawn:
            TNT1 A 5;
            HLBL CDEFGHIJKLMN 3;
            TNT1 A 0;
            Stop;
    }
}

class ArtyMarker : Actor {
    default {}
    double timer;

    void Ring(double rad) {
        for (double i = 0; i < 360; i += 30) {
            A_SpawnParticle("FF0000",SPF_FULLBRIGHT|SPF_RELATIVE,1,16,i,rad);
        }
    }

    void Ring2(double rad) {
        for (double i = 0; i < 360; i += 30) {
            A_SpawnParticle("FF9900",SPF_FULLBRIGHT|SPF_RELATIVE,1,16,i,rad);
        }
    }

    void Spike() {
        A_SpawnParticle("FF0000",SPF_FULLBRIGHT,35,16,velz:4);
    }

    state Arty() {
        if (timer < 2.5) {
            timer += 1./35.;
            Ring(80);
            Ring2(80 * (1 - (timer/2.5)));
            Spike();
            return ResolveState(null);
        } else {
            return ResolveState("Death");
        }
    }

    states {
        Spawn:
            TNT1 A 35;
        Tick:
            TNT1 A 1 Arty();
            Loop;
        
        Death:
            MISL B 0 A_StartSound("weapons/rocklx");
            MISL B 5 A_Explode(80);
            MISL CD 5;
            TNT1 A 0;
            Stop;
    }
}