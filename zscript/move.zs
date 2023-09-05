extend class DMDMonster {
    // Movement code hacked together out of Kizoky's zscriptified chase functions:
    // https://github.com/Kizoky/CPPtoZScript
    // Without this, I wouldn't even know where to start.
    // How fast the monster can approach its goal angle.
    double turnrate;
    Property TurnRate : turnrate;

    // How much to turn when strafing.
    double maxturn;
    Property MaxTurn : maxturn;

	// The lowest and highest random values for the movecount to be reset to.
	// Higher means longer waiting period between shots.
	int mlo,mhi;
	Property MWait : mlo,mhi;

	// How much sine wave wiggle should we add to the monster's movement?
	double wiggleamp, wigglefreq;
	Property Wiggle : wiggleamp, wigglefreq;

    default {
		+SLIDESONWALLS;
        DMDMonster.TurnRate 5.;
		DMDMonster.MWait 7,15;
		DMDMonster.Wiggle 1, 1;
        DMDMonster.MaxTurn 45;
        BloodColor "FC0330";
    }

    const CLASS_BOSS_STRAFE_RANGE = 64 * 10; // magic number, I guess

    double goalang;

    void A_DoMove(bool fastchase, State meleestate, State missilestate, bool playActive, bool nightmareFast, bool dontMove, int flags) {
        if (bInConversation)
			return;

		if (bInChase)
			return;

		bInChase = true;

		bool isFast = bALWAYSFAST ? true : false;

		// [RH] Andy Baker's stealth monsters
		if (bStealth)
			visdir = -1;

		if (reactiontime)
			reactiontime--;

		// [RH] Don't chase invisible targets
		if (target != null &&
			target.bINVISIBLE &&
			target != goal)
		{
			target = null;
		}

		// modify target threshold
		if (!target || (target && target.Health <= 0))
			threshold = 0;
		else
			threshold--;

		// Monsters move faster in nightmare mode
		if (nightmareFast && G_SkillPropertyInt (SKILLP_FastMonsters))
		{
			if (tics > 3)
			{
				tics -= tics / 2;
				if (tics < 3)
				{
					tics = 3;
				}
			}
		}

		// turn towards movement direction if not there yet
        if (!(flags & CHF_NODIRECTIONTURN))
		{
            Turn();
		}

		// [RH] Friendly monsters will consider chasing whoever hurts a player if they
		// don't already have a target.
		if (bFRIENDLY && target == null)
		{
			PlayerInfo player;

			if (FriendPlayer != 0)
			{
				player = Players[FriendPlayer - 1];
			}
			else
			{
				int i;
				if (!multiplayer)
				{
					i = 0;
				}
				else for (i = random[newchasedirr](0,255) & (MAXPLAYERS-1); !PlayerInGame[i]; i = (i+1) & (MAXPLAYERS-1))
				{
				}

				player = Players[i];
			}
			if (player.attacker && player.attacker.health > 0 && player.attacker.bSHOOTABLE && random[newchasedirr](0,255) < 80)
			{
				if (!player.attacker.bFRIENDLY ||
					deathmatch && FriendPlayer != 0 && player.attacker.FriendPlayer != 0 &&
					FriendPlayer != player.attacker.FriendPlayer)
				{
					target = player.attacker;
				}
			}
		}

		// do not attack twice in a row
		if (bJUSTATTACKED)
		{
            if (movecount <= 0) {
                bJUSTATTACKED = false;
            }
			if (!isFast && !dontmove && !(flags & CHF_NOPOSTATTACKTURN) && !(flags & CHF_STOPIFBLOCKED))
			{
				// NewChaseDir();
                A_DoMoveEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);
			}
			//Because P_TryWalk would never be reached if the actor is stopped by a blocking object,
			//need to make sure the movecount is reset, otherwise they will just keep attacking
			//over and over again.
			if (flags & CHF_STOPIFBLOCKED) {
				// movecount = TryWalk() & 15;
                Turn();
            }
			bINCHASE = false;
			return;
		}

		// [RH] Don't attack if just moving toward goal
		if (target == goal || bChaseGoal && goal != null)
		{
			actor savedtarget = target;
			target = goal;
            bool result = false;
            if (savedtarget) {
                double dist = Distance2D(savedtarget);
                result = (dist >= MeleeRange + radius + savedtarget.radius) ? true : false;
                target = savedtarget;
            }

			if (result)
			{
				// reached the goal
				ActorIterator iterator = Level.CreateActorIterator(goal.args[0], "PatrolPoint");
				ActorIterator specit = Level.CreateActorIterator(goal.tid, "PatrolSpecial");
				Actor spec;

				// Execute the specials of any PatrolSpecials with the same TID
				// as the goal.
				while ( (spec = specit.Next()) )
				{
					level.ExecuteSpecial(
						spec.special, self, null, false,
						spec.args [0], spec.args [1], spec.args [2], spec.args [3], spec.args [4]
					);
				}

				double lastgoalang = goal.angle;
				int delay;
				actor newgoal = iterator.Next ();
				if (newgoal != null && goal == target)
				{
					delay = newgoal.args[1];
					reactiontime = delay * TICRATE + level.maptime;
				}
				else
				{
					delay = 0;
					reactiontime = Default.reactiontime;
					angle = lastgoalang;
				}
				if (target == goal) target = null;
				bJUSTATTACKED = true;
				if (newgoal != null && delay != 0)
				{
					bINCOMBAT = true;
					SetIdle();
				}
				bINCHASE = false;
				goal = newgoal;
				return;
			}
		}
		if (goal == target) A_DoMoveEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);

		// Strafe	(Hexen's class bosses)
		// This was the sole reason for the separate A_FastChase function but
		// it can be just as easily handled by a simple flag so the monsters
		// can take advantage of all the other enhancements of A_Chase.

		if (fastchase && !dontmove)
		{
			if (FastChaseStrafeCount > 0)
			{
				FastChaseStrafeCount--;
			}
			else
			{
				FastChaseStrafeCount = 0;
				Vel.X = Vel.Y = 0;
				double dist = Distance2D(target);
				if (dist < CLASS_BOSS_STRAFE_RANGE)
				{
					if (random[pr_chase](0,255) < 100)
					{
						double ang = AngleTo(target);
						if (random[pr_chase](0,255) < 128) ang += 90.;
						else ang -= 90.;
						VelFromAngle(13., ang);
						FastChaseStrafeCount = 3;	// strafe time
					}
				}
			}
		}

		// [RH] Scared monsters attack less frequently
		if ((target && target.player == null) || 
			!(target && target.player.cheats & CF_FRIGHTENING) || (target && target.bFRIGHTENING &&
			bFRIGHTENED) ||
			random[pr_scaredycat](0,255) < 43)
		{
			// check for melee attack
			if (meleestate && CheckMeleeRange ())
			{
				if (AttackSound)
					A_StartSound(AttackSound, CHAN_WEAPON);

				SetState (meleestate);
				bINCHASE = false;
				return;
			}

			// check for missile attack
			if (missilestate)
			{
                if ((isFast || !bJUSTATTACKED) && CheckMissileRange()) {
                    SetState(missilestate);
                    bJUSTATTACKED = true;
                    bINCOMBAT = true;
                    bINCHASE = false;
                    return;
                } else {
					A_DoMoveEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);
                }
			}
		}

		A_DoMoveEnd (fastChase, meleestate, missilestate, playActive, nightmareFast, dontMove, flags);
    }

    void A_DoMoveEnd(bool fastchase, State meleestate, State missilestate, bool playActive, bool nightmareFast, bool dontMove, int flags)
	{
		if ((multiplayer || TIDtoHATE)
			&& !threshold
			&& !CheckSight(target,0) )
		{
			bool lookForBetter = false;
			bool gotNew;
			if (bNOSIGHTCHECK)
			{
				bNOSIGHTCHECK = false;
				lookForBetter = true;
			}
			actor oldtarget = target;
			gotNew = LookForPlayers(true,null);
			if (lookForBetter)
			{
				bNOSIGHTCHECK = true;
			}
			if (gotNew && target != oldtarget)
			{
				bINCHASE = false;
				return;
			}
		}

		//
		// chase towards player
		//

		if (strafecount)
			strafecount--;

		// class bosses don't do this when strafing
		if ((!fastchase || !FastChaseStrafeCount) && !dontmove)
		{
			// CANTLEAVEFLOORPIC handling was completely missing in the non-serpent functions.
			vector2 old = pos.XY;
			//int oldgroup = PrevPortalGroup
			TextureID oldFloor = floorpic;

			double truespd = GetTrueSpd();

			// Chase towards player
			if ((--movecount < 0 && !(flags & CHF_NORANDOMTURN)) || !(flags & CHF_StopIfBlocked))
			{
				// NewChaseDir();
                Turn();
			}
			if (CheckValidMove(vel.length() + radius)) {
				Step(truespd);
			} else {
				// Turn();
				double newang = (180 + frandom(-30,30));
				angle += newang;
				goalang += newang;
                vel = (0,0,vel.z);
			}
			// if the move was illegal, reset it 
			// (copied from A_SerpentChase - it applies to everything with CANTLEAVEFLOORPIC!)
			if (bCANTLEAVEFLOORPIC && floorpic != oldFloor)
			{
				if (CheckMove(old))
				{
					if (nomonsterinterpolation)
					{
						Prev.X = old.X;
						Prev.Y = old.Y;
						//PrevPortalGroup = oldgroup;
					}
				}
				if (!(flags & CHF_STOPIFBLOCKED))
					// NewChaseDir();
                    Turn();

			}
		}
		else if (dontmove && movecount > 0) movecount--;

		// make active sound
		if (playactive && random[pr_chase](0,255) < 3)
		{
			PlayActiveSound();
		}

		bINCHASE = false;

	}

    void Step(double truespd) {
        // Move a single step in our current facing dir.
        double diff = abs(DeltaAngle(Normalize180(angle),Normalize180(goalang)));
        double mult = 180. / (180. + diff); // Should yield a value between 1 and 0.5, depending on how close to the goal angle it is.
        Thrust(truespd * mult,angle);
    }

	double GetTrueSpd() {
		return speed * 1./35. * curstate.tics;
	}

    void Turn() {
        // Pick an angle to move in.
        angle = Normalize180(angle); // Prevent some angle weirdness.
        if (movecount<0) {
            goalang = angle;
            if (goal) {
                console.printf("Following goal");
                goalang = AngleTo(goal);
            } else if (target && target != goal) {
                goalang = AngleTo(target);
                if (bFRIGHTENED) {
                    // Run away!!
                    goalang = goalang+180;
                }
            } 
            goalang += frandom(-maxturn,maxturn);
            movecount = random(mlo,mhi);
            goalang = Normalize180(goalang);
        }
		double wiggle = sin(GetAge() * wigglefreq) * wiggleamp;
        double dang = Normalize180(DeltaAngle(angle, goalang+wiggle));
        if (dang < turnrate) {
            angle = goalang;
        } else {
            if (dang < 0) {
                angle -= turnrate;
            } else {
                angle += turnrate;
            }
        }
    }

	bool CheckValidMove(double truespd) {
		FLineTraceData trace;
		Vector2 nextpos;
		bool hit = LineTrace(angle,truespd,0,flags:TRF_SOLIDACTORS,offsetz:MaxStepHeight,data: trace);
		if (hit) {
			nextpos = trace.HitLocation.XY;
		} else {
			nextpos = pos.XY + AngleToVector(angle,truespd);
		}
		FCheckPosition info;
		bool res = CheckPosition(nextpos,false,info);
		if (res) {
			if (!bDROPOFF && pos.z - info.floorz > MaxDropOffHeight) { res = false; }
		}

		return res;
	}

    action void A_Move (StateLabel melee = "Melee", StateLabel missile = "Missile", int flags = 0)
	{
        invoker.A_DoMove ((flags & CHF_FastChase), ResolveState (melee), ResolveState (missile), !(flags & CHF_NoPlayActive),
            (flags & CHF_NightmareFast), (flags & CHF_DontMove), flags
        );
    }
}