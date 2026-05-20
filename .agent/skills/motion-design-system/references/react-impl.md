# ⚛️ Implémentation React/Web — Motion Design System

> **Contexte** : Implémentation des tokens et micro-interactions dans un projet React, Next.js ou web vanilla. Lire **uniquement** si la plateforme cible est web.

---

## 1. Structure de fichiers recommandée

```
src/
└── design-system/
    └── motion/
        ├── tokens.css              ← Variables CSS (copier depuis tokens.md)
        ├── motion-tokens.ts        ← Types TypeScript + constantes JS
        ├── use-reduced-motion.ts   ← Hook prefers-reduced-motion
        ├── animated-appear.tsx     ← Composant appear-fade-slide
        ├── animated-press.tsx      ← Composant press-shrink
        ├── animated-stagger.tsx    ← Liste stagée
        └── page-transition.tsx     ← Framer Motion page transition
```

---

## 2. Hook `useReducedMotion`

```typescript
// src/design-system/motion/use-reduced-motion.ts
import { useEffect, useState } from 'react';

export function useReducedMotion(): boolean {
  const [reduce, setReduce] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReduce(mq.matches);
    const handler = (e: MediaQueryListEvent) => setReduce(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return reduce;
}
```

---

## 3. Tokens TypeScript

```typescript
// src/design-system/motion/motion-tokens.ts

export const MotionDuration = {
  instant:    100,
  short:      150,
  standard:   250,
  long:       400,
  deliberate: 500,
} as const;

export const MotionEasing = {
  standard:   [0.2, 0.0, 0, 1.0],
  decelerate: [0.0, 0.0, 0.2, 1.0],
  accelerate: [0.4, 0.0, 1.0, 1.0],
  emphasized: [0.4, 0.0, 0.2, 1.0],
  bounce:     [0.34, 1.56, 0.64, 1.0],
} as const;

export const MotionScale = {
  press:   0.97,
  hover:   1.02,
  success: 1.05,
} as const;

export const MotionStagger = {
  tight:    20,
  standard: 40,
  loose:    60,
} as const;
```

---

## 4. Composant `AnimatedAppear`

```tsx
// src/design-system/motion/animated-appear.tsx
import { motion, AnimatePresence } from 'framer-motion';
import { useReducedMotion } from './use-reduced-motion';
import { MotionDuration, MotionEasing } from './motion-tokens';

interface AnimatedAppearProps {
  children: React.ReactNode;
  delay?: number;
  className?: string;
}

export function AnimatedAppear({
  children,
  delay = 0,
  className,
}: AnimatedAppearProps) {
  const reduceMotion = useReducedMotion();

  const variants = {
    hidden: {
      opacity: 0,
      y: reduceMotion ? 0 : 8,
    },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: MotionDuration.standard / 1000,
        ease: MotionEasing.decelerate,
        delay: delay / 1000,
      },
    },
  };

  return (
    <motion.div
      className={className}
      initial="hidden"
      animate="visible"
      variants={variants}
    >
      {children}
    </motion.div>
  );
}
```

---

## 5. Composant `AnimatedPress`

```tsx
// src/design-system/motion/animated-press.tsx
import { motion } from 'framer-motion';
import { useReducedMotion } from './use-reduced-motion';
import { MotionDuration, MotionEasing, MotionScale } from './motion-tokens';

interface AnimatedPressProps {
  children: React.ReactNode;
  onClick?: () => void;
  className?: string;
}

export function AnimatedPress({ children, onClick, className }: AnimatedPressProps) {
  const reduceMotion = useReducedMotion();

  return (
    <motion.div
      className={className}
      onClick={onClick}
      whileTap={
        reduceMotion
          ? { opacity: 0.7 }
          : { scale: MotionScale.press }
      }
      transition={{
        duration: MotionDuration.instant / 1000,
        ease: MotionEasing.accelerate,
      }}
    >
      {children}
    </motion.div>
  );
}
```

---

## 6. Composant `AnimatedStagger`

```tsx
// src/design-system/motion/animated-stagger.tsx
import { motion } from 'framer-motion';
import { useReducedMotion } from './use-reduced-motion';
import { MotionDuration, MotionEasing, MotionStagger } from './motion-tokens';

interface AnimatedStaggerProps {
  children: React.ReactNode[];
  staggerDelay?: number;
}

export function AnimatedStagger({
  children,
  staggerDelay = MotionStagger.standard,
}: AnimatedStaggerProps) {
  const reduceMotion = useReducedMotion();

  const container = {
    hidden: {},
    visible: {
      transition: {
        staggerChildren: reduceMotion ? 0 : staggerDelay / 1000,
      },
    },
  };

  const item = {
    hidden: { opacity: 0, y: reduceMotion ? 0 : 8 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: MotionDuration.standard / 1000,
        ease: MotionEasing.decelerate,
      },
    },
  };

  return (
    <motion.div initial="hidden" animate="visible" variants={container}>
      {children.map((child, i) => (
        <motion.div key={i} variants={item}>
          {child}
        </motion.div>
      ))}
    </motion.div>
  );
}
```

---

## 7. Transitions de page (Next.js App Router)

```tsx
// src/design-system/motion/page-transition.tsx
'use client';
import { motion, AnimatePresence } from 'framer-motion';
import { useReducedMotion } from './use-reduced-motion';
import { MotionDuration, MotionEasing } from './motion-tokens';

interface PageTransitionProps {
  children: React.ReactNode;
  routeKey: string;
}

export function PageTransition({ children, routeKey }: PageTransitionProps) {
  const reduceMotion = useReducedMotion();

  const variants = {
    hidden:  { opacity: 0, x: reduceMotion ? 0 : 24 },
    visible: { opacity: 1, x: 0 },
    exit:    { opacity: 0, x: reduceMotion ? 0 : -8 },
  };

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={routeKey}
        variants={variants}
        initial="hidden"
        animate="visible"
        exit="exit"
        transition={{
          duration: MotionDuration.long / 1000,
          ease: MotionEasing.emphasized,
        }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  );
}
```

---

## 8. Micro-interactions CSS pures (sans Framer)

```css
/* Hover elevate */
.hoverable {
  transition:
    transform var(--motion-duration-short) var(--motion-easing-standard),
    box-shadow var(--motion-duration-short) var(--motion-easing-standard);
}
.hoverable:hover {
  transform: translateY(calc(-1 * var(--motion-path-shift-xs)));
  box-shadow: 0 8px 24px rgb(0 0 0 / 0.12);
}

/* Press shrink */
.pressable:active {
  transform: scale(var(--motion-scale-press));
  transition: transform var(--motion-duration-instant) var(--motion-easing-accelerate);
}

/* Error shake */
@keyframes error-shake {
  0%, 100% { transform: translateX(0); }
  20%      { transform: translateX(calc(-1 * var(--motion-path-shift-xs))); }
  40%      { transform: translateX(var(--motion-path-shift-xs)); }
  60%      { transform: translateX(calc(-0.6 * var(--motion-path-shift-xs))); }
  80%      { transform: translateX(calc(0.3 * var(--motion-path-shift-xs))); }
}
.error-shake { animation: error-shake 400ms linear 1; }

/* Prefers reduced motion */
@media (prefers-reduced-motion: reduce) {
  .hoverable, .pressable { transition: opacity 0.1s linear; }
  .hoverable:hover { transform: none; }
  .pressable:active { transform: none; opacity: 0.7; }
}
```

---

## 9. Intégration avec les autres skills

| Situation | Action |
|-----------|--------|
| Besoin d'un design system complet | → `ui-ux-pro-max --design-system` |
| Besoin de principes UX web | → `frontend-design` |
| Besoin d'animations GSAP avancées | → `gsap-core` + `gsap-timeline` |
| Prototypage interactif HTML | → `huashu-design` |
| Scroll-triggered animations | → `gsap-scrolltrigger` |
