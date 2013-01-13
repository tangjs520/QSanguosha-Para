#ifndef _BGM_H
#define _BGM_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "standard.h"

class BGMPackage: public Package {
    Q_OBJECT

public:
    BGMPackage();
};

class LihunCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE LihunCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class DaheCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE DaheCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class TanhuCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE TanhuCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class YanxiaoCard: public DelayedTrick {
    Q_OBJECT

public:
    Q_INVOKABLE YanxiaoCard(Card::Suit suit, int number);

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void takeEffect(ServerPlayer *) const;
};

class YinlingCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE YinlingCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class BGMDIYPackage: public Package {
    Q_OBJECT

public:
    BGMDIYPackage();
};

class LangguCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE LangguCard();

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class FuluanCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE FuluanCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class HuangenCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE HuangenCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class HantongCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE HantongCard();
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class DIYYicongCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE DIYYicongCard();
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

#endif

