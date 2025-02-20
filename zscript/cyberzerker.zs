class Cyberzerker : DMDMonster replaces Demon {
    // A demented zombie with some kind of zappy melee weapon strapped to its arm.
    // 1. Performs 3 dashes, doing 20 damage to anything it passes by and popping them into the air slightly.
    // 2. Charges briefly, then uppercuts for 40 damage, launching itself and everything nearby into the air.
    int dashcount;
    Array<Actor> hit;
    bool charging;
    bool prepcharge;
    bool prepupper;

    default {
        Health 150; // Roughly as healthy as the original.
        Radius 20; // Slightly thinner, though!
        Height 56;
        Speed 12; // Watch out, this one's a speed demon.
        Mass 200; // It's not as heavy as the original.
        PainChance 180;
        +FLOORCLIP;
        +DROPOFF;
        SeeSound "demon/sight";
		AttackSound "demon/melee";
		PainSound "demon/pain";
		DeathSound "demon/death";
		ActiveSound "demon/active";
        Obituary "%o was butchered by the Cyberzerkers.";
        DropItem "ArmorBonus";
        DropItem "ArmorBonus";
        DropItem "Stimpack",64;
    }

    override State ChooseAttack() {
        if (Vec3To(target).length() < 240) {
            return ResolveState("Uppercut");
        } else {
            return ResolveState("Dash");
        }
    }

    override void AttackPrep(State atk) {
        if (atk.InStateSequence(ResolveState("Dash"))) {
            prepcharge = true;
        }

        if (atk.InStateSequence(ResolveState("Uppercut")) || health <= 75) {
            prepupper = true;
        }
    }

    override void AttackFinish() {
        prepcharge = false;
        prepupper = false;
    }

    override void Tick() {
        Super.Tick();
        if (prepcharge) {
            // Draw the warning ring.
            for (double i = 0; i < 360; i += 30) {
                A_SpawnParticle("FF0000",SPF_FULLBRIGHT|SPF_RELATIVE,1,16,i,90,0,height*0.5);
            }
        }

        if (prepupper) {
            // Larger warning ring.
            for (double i = 0; i < 360; i += 30) {
                A_SpawnParticle("FF0000",SPF_FULLBRIGHT|SPF_RELATIVE,1,16,i,120,0,height*0.5);
            }
        }
        if (charging) {
            // First, draw a danger ring.
            // Grab all entities that are A) not on our list and B) within 260 units of this one.
            ThinkerIterator it = ThinkerIterator.Create("Actor");
            Actor mo;
            while (mo = Actor(it.next())) {
                if (mo == self || !mo.bSHOOTABLE) {
                    continue;
                }

                if (hit.find(mo) < hit.size()) {
                    continue;
                }

                if (!CheckSight(mo)) {
                    continue;
                }

                Vector3 dv = Vec3To(mo);
                Vector3 dir = dv.unit();
                Double dist = dv.length();
                if (dist > 90) {
                    continue;
                } 

                // Now we spawn some zappy particles and do damage.
                for(int i = 0; i < dist; i += random(3,6)) {
                    A_SpawnParticle("00FFFF",SPF_FULLBRIGHT,35,frandom(3,6),0,dir.x * i, dir.y * i, (dir.z * i) + (height * 0.5));
                }
                mo.DamageMobj(self,self,20,"electric");
                mo.Vel3DFromAngle(20,AngleTo(mo,true),-30);
                hit.push(mo);
            }
        }
    }

    void ChargeStart() {
        charging = true;
    }

    void ChargeEnd() {
        hit.clear();
        charging = false;
    }

    action void Uppercut() {
        RadiusShock(20,120,-60,40,"electric");
    }

    states {
        Spawn:
            ZFOD AB Random(8,12) A_Look();
            Loop;
        
        See:
            ZFOD ABCD 3 A_Move();
            Loop;
        
        Missile:
            ZFOD A 0 StartAttack();
            Goto See;
        
        Dash:
            ZFOD E 3 Aim(0,270); // Hoizontal only!
            ZFOD E 12 A_StartSound("demon/sight");
        DashLoop:
            ZFOD E 9 Aim(75,270);
            ZFOD F 0 {
                A_StartSound("zerker/saw");
                ChargeStart();
                invoker.DashCount += 1;
                invoker.Thrust(30,angle);
            }
            ZFOD FGFG 2;
            ZFOD E 6 ChargeEnd();
            ZFOD E 0 A_JumpIf(invoker.DashCount >= 3, "DashEnd");
            Loop;

        DashEnd:
            ZFOD E 0 {
                invoker.dashcount = 0;
            }
            ZFOD F 6 A_JumpIf(health <= 75,"Uppercut");
            ZFOD E 3 EndAttack();
            Goto See;
        
        Uppercut:
            ZFOD EEEEEEEE 2 A_StartSound("zerker/rev");
            ZFOD E 2 A_StartSound("zerker/saw");
            ZFOD E 2 Aim(0,270);
            ZFOD F 0 {
                Uppercut();
                invoker.Vel3DFromAngle(20,0,-90);
            }
            ZFOD FGFGFGFG 2 {
                invoker.angle += 45;
            }
            ZFOD E 12;
            ZFOD E 6 EndAttack();
            Goto See;

        Pain:
            ZFOD H 2 ChargeEnd();
            ZFOD H 4 A_Pain();
            ZFOD F 10 {
                invoker.Thrust(20,invoker.angle-180);
            }
            ZFOD E 4 EndAttack();
            Goto See;
        
        Death:
            ZFOD H 4 ChargeEnd();
            ZFOD I 7 A_Scream();
            ZFOD J 6 A_NoBlocking();
            ZFOD KL 5;
            ZFOD M 1 A_StartSound("misc/thud");
            ZFOD M -1;
            Stop;
        XDeath:
            ZFOD H 2 ChargeEnd();
            ZFOD H 4 A_Scream();
            ZFOD N 4 A_XScream();
            ZFOD O 4 A_NoBlocking();
            ZFOD PQRS 4;
            ZFOD S -1;
            Stop;
        
        Raise:
            ZFOD LKJI 5;
            ZFOD H 3 A_Pain();
            Goto See;

    }
}

class MadCyberzerker : Cyberzerker replaces Spectre {
    // A more dangerous Cyberzerker that has less health.
    default {
        Health 75; // Always combos dash into uppercut!
    }
}