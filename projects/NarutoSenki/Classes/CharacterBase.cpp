{
	_isCanSkill3 = true;
}

/**
 * Utilities
 */

void CharacterBase::increaseAllCkrs(uint32_t value, bool enableLv2, bool enableLv4)
{
	if (_level >= 2 && enableLv2)
	{
		uint32_t ckr = MIN(getCKR() + value, 45000);
		setCKR(ckr);

		if (ckr >= 15000)
			_isCanOugis1 = true;

		if (isPlayer())
			getGameLayer()->setCKRLose(false);
	}

	if (_level >= 4 && enableLv4)
	{
		uint32_t ckr2 = MIN(getCKR2() + value, 50000);
		setCKR2(ckr2);

		if (ckr2 >= 25000)
			_isCanOugis2 = true;

		if (isPlayer())
			getGameLayer()->setCKRLose(true);
	}
}

void CharacterBase::increaseHpAndUpdateUI(uint32_t value)
{
	setHPValue(MIN(getHP() + value, getMaxHP()));
}

void CharacterBase::updateHpBar()
{
	if (_hpBar)
		_hpBar->loseHP(getHpPercent());
}
