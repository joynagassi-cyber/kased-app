import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { MotionDuration, MotionEasing, MotionScale } from '../../references/motion-tokens';
import { useReducedMotion } from '../../references/use-reduced-motion';

/**
 * Exemple de transition d'entrée de Modal chorégraphiée.
 * Respecte les phases : Overlay -> Conteneur -> Titre -> Contenu -> Actions.
 */
export const ModalEntranceExample = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="p-8">
      <button
        onClick={() => setIsOpen(true)}
        className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
      >
        Ouvrir le Modal
      </button>

      <AnimatePresence>
        {isOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* 1. Overlay - Fade in */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsOpen(false)}
              className="absolute inset-0 bg-black/50 backdrop-blur-sm"
              transition={{ duration: MotionDuration.standard / 1000 }}
            />

            {/* 2. Conteneur du Modal */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="relative w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden"
              transition={{
                duration: MotionDuration.standard / 1000,
                ease: MotionEasing.emphasized,
              }}
            >
              <div className="p-6">
                {/* 3. Titre - Apparition avec léger délai */}
                <motion.h2
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{
                    delay: 0.1,
                    duration: MotionDuration.short / 1000,
                    ease: MotionEasing.decelerate,
                  }}
                  className="text-2xl font-bold text-gray-900"
                >
                  Confirmer l'action
                </motion.h2>

                {/* 4. Contenu - Fade slide */}
                <motion.p
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{
                    delay: 0.15,
                    duration: MotionDuration.standard / 1000,
                    ease: MotionEasing.decelerate,
                  }}
                  className="mt-4 text-gray-600"
                >
                  Êtes-vous sûr de vouloir valider cette opération ? Cette action est irréversible et sera enregistrée dans les logs système.
                </motion.p>

                {/* 5. Actions - Staggered entrance */}
                <div className="mt-8 flex justify-end gap-3">
                  <motion.button
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    whileTap={{ scale: MotionScale.press }}
                    onClick={() => setIsOpen(false)}
                    className="px-4 py-2 text-gray-700 font-medium hover:bg-gray-100 rounded-lg transition-colors"
                    transition={{
                      delay: 0.2,
                      duration: MotionDuration.short / 1000,
                    }}
                  >
                    Annuler
                  </motion.button>
                  
                  <motion.button
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    whileTap={{ scale: MotionScale.press }}
                    onClick={() => {
                      alert('Action validée !');
                      setIsOpen(false);
                    }}
                    className="px-6 py-2 bg-blue-600 text-white font-bold rounded-lg shadow-lg shadow-blue-200"
                    transition={{
                      delay: 0.25,
                      duration: MotionDuration.short / 1000,
                    }}
                  >
                    Confirmer
                  </motion.button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};
