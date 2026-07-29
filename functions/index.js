const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();
setGlobalOptions({maxInstances: 10});

exports.deleteUserCompletely = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para realizar esta acción",
    );
  }

  const callerDoc = await admin
      .firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new HttpsError(
        "permission-denied",
        "Solo un administrador puede eliminar usuarios",
    );
  }

  const uid = request.data.uid;

  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "UID no recibido");
  }

  if (uid === request.auth.uid) {
    throw new HttpsError(
        "invalid-argument",
        "Un administrador no puede eliminarse a sí mismo desde aquí",
    );
  }

  try {
    await admin.firestore().collection("players").doc(uid).delete();
    await admin.firestore().collection("users").doc(uid).delete();
    await admin.auth().deleteUser(uid);
    return {
      success: true,
      message: "Usuario eliminado correctamente",
    };
  } catch (e) {
    console.error(e);

    throw new HttpsError(
        "internal",
        "No se pudo eliminar el usuario",
    );
  }
});
