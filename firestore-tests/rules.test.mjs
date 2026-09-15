import { before, beforeEach, after, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const ADMIN_UID = 'admin-uid';
const USER_UID = 'user-uid';
const OTHER_UID = 'other-uid';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'padel-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  // Documentos de usuario base que las reglas necesitan consultar
  // (isAdmin() hace un get sobre users/{uid}).
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc(`users/${ADMIN_UID}`).set({ role: 'admin' });
    await db.doc(`users/${USER_UID}`).set({ role: 'user' });
    await db.doc(`users/${OTHER_UID}`).set({ role: 'user' });
    await db.doc('matches/match1').set({ club: 'Test Club' });
    await db.doc('clubs/club1').set({ name: 'Test Club' });
  });
});

function asAdmin() {
  return testEnv.authenticatedContext(ADMIN_UID).firestore();
}
function asUser() {
  return testEnv.authenticatedContext(USER_UID).firestore();
}
function asAnon() {
  return testEnv.unauthenticatedContext().firestore();
}

describe('usuarios anónimos', () => {
  it('no pueden leer partidos', async () => {
    await assertFails(asAnon().doc('matches/match1').get());
  });

  it('no pueden leer jugadores', async () => {
    await assertFails(asAnon().doc('players/x').get());
  });

  it('no pueden leer clubes', async () => {
    await assertFails(asAnon().doc('clubs/club1').get());
  });

  it('no pueden leer perfiles de usuario', async () => {
    await assertFails(asAnon().doc(`users/${USER_UID}`).get());
  });
});

describe('usuario autenticado sin rol admin', () => {
  it('puede leer partidos', async () => {
    await assertSucceeds(asUser().doc('matches/match1').get());
  });

  it('no puede crear un partido', async () => {
    await assertFails(asUser().doc('matches/match2').set({ club: 'X' }));
  });

  it('no puede editar un partido', async () => {
    await assertFails(
      asUser().doc('matches/match1').update({ club: 'Hackeado' }),
    );
  });

  it('no puede borrar un partido', async () => {
    await assertFails(asUser().doc('matches/match1').delete());
  });

  it('no puede crear un club', async () => {
    await assertFails(asUser().doc('clubs/club2').set({ name: 'X' }));
  });

  it('puede crear su propia ficha de jugador', async () => {
    await assertSucceeds(
      asUser()
        .doc(`players/${USER_UID}`)
        .set({ name: 'Yo', surname: 'Mismo' }),
    );
  });

  it('no puede crear la ficha de jugador de otra persona', async () => {
    await assertFails(
      asUser()
        .doc(`players/${OTHER_UID}`)
        .set({ name: 'Suplantado', surname: 'X' }),
    );
  });

  it('puede editar su propia ficha de jugador', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`players/${USER_UID}`)
        .set({ name: 'Yo' });
    });
    await assertSucceeds(
      asUser().doc(`players/${USER_UID}`).update({ name: 'Actualizado' }),
    );
  });

  it('no puede borrar ni su propia ficha de jugador', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`players/${USER_UID}`)
        .set({ name: 'Yo' });
    });
    await assertFails(asUser().doc(`players/${USER_UID}`).delete());
  });

  it('no puede cambiar el userId de su propia ficha de jugador', async () => {
    // El admin borra la cuenta users/{userId} vinculada a un jugador al
    // eliminarlo; si el dueño pudiera reapuntar userId a otra persona,
    // conseguiría que el admin borrase por error la cuenta de otro.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`players/${USER_UID}`)
        .set({ name: 'Yo', userId: USER_UID });
    });
    await assertFails(
      asUser()
        .doc(`players/${USER_UID}`)
        .update({ userId: OTHER_UID }),
    );
  });

  it('puede seguir editando otros campos si no toca userId', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`players/${USER_UID}`)
        .set({ name: 'Yo', userId: USER_UID });
    });
    await assertSucceeds(
      asUser()
        .doc(`players/${USER_UID}`)
        .update({ name: 'Actualizado', userId: USER_UID }),
    );
  });

  it('puede leer su propio perfil', async () => {
    await assertSucceeds(asUser().doc(`users/${USER_UID}`).get());
  });

  it('no puede leer el perfil de otra persona', async () => {
    await assertFails(asUser().doc(`users/${OTHER_UID}`).get());
  });

  it('puede registrarse creando su perfil con role "user"', async () => {
    const newUserDb = testEnv.authenticatedContext('new-uid').firestore();
    await assertSucceeds(
      newUserDb.doc('users/new-uid').set({ role: 'user', name: 'Nuevo' }),
    );
  });

  it('no puede autoasignarse el rol admin al registrarse', async () => {
    const newUserDb = testEnv.authenticatedContext('new-uid').firestore();
    await assertFails(
      newUserDb.doc('users/new-uid').set({ role: 'admin', name: 'Nuevo' }),
    );
  });

  it('no puede cambiarse el rol a admin editando su perfil', async () => {
    await assertFails(
      asUser().doc(`users/${USER_UID}`).update({ role: 'admin' }),
    );
  });

  it('puede editar otros campos de su propio perfil', async () => {
    await assertSucceeds(
      asUser().doc(`users/${USER_UID}`).update({ phone: '600000000' }),
    );
  });
});

describe('administrador', () => {
  it('puede crear, editar y borrar partidos', async () => {
    await assertSucceeds(asAdmin().doc('matches/match2').set({ club: 'X' }));
    await assertSucceeds(
      asAdmin().doc('matches/match1').update({ club: 'Editado' }),
    );
    await assertSucceeds(asAdmin().doc('matches/match1').delete());
  });

  it('puede crear clubes', async () => {
    await assertSucceeds(asAdmin().doc('clubs/club2').set({ name: 'X' }));
  });

  it('puede borrar la ficha de cualquier jugador', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc(`players/${OTHER_UID}`).set({});
    });
    await assertSucceeds(asAdmin().doc(`players/${OTHER_UID}`).delete());
  });

  it('no puede ascender a otro usuario a admin ni siquiera él mismo', async () => {
    // El rol es inmutable por diseño: solo se cambia desde la
    // consola/Admin SDK, nunca desde un cliente, ni siquiera admin.
    await assertFails(
      asAdmin().doc(`users/${OTHER_UID}`).update({ role: 'admin' }),
    );
  });
});

describe('colecciones no contempladas', () => {
  it('quedan denegadas incluso para el admin', async () => {
    await assertFails(asAdmin().doc('secrets/x').set({ v: 1 }));
  });
});
