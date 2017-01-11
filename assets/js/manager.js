import { config } from './config';
import { createCryptoManager, generateRandomPassword } from './crypto';

window.yapm = {
  config: config,
  createCryptoManager: createCryptoManager,
  generateRandomPassword: generateRandomPassword,
};
