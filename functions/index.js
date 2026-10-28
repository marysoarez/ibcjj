"use strict";

const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {logger} = require("firebase-functions");
const {setGlobalOptions} = require("firebase-functions/v2");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

initializeApp();
setGlobalOptions({region: "southamerica-east1", maxInstances: 10});

const RECENT_LOGIN_SECONDS = 10 * 60;

async function deleteQuery(query) {
  while (true) {
    const snapshot = await query.limit(400).get();
    if (snapshot.empty) return;

    const batch = getFirestore().batch();
    for (const document of snapshot.docs) batch.delete(document.ref);
    await batch.commit();
  }
}

async function deleteStorageData(uid) {
  const bucket = getStorage().bucket();
  const prefixes = [
    `usuarios/${uid}/`,
    `certificados/${uid}/`,
  ];

  for (const prefix of prefixes) {
    await bucket.deleteFiles({prefix, force: true});
  }
}

exports.deleteOwnAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const uid = request.auth.uid;
  const authTime = Number(request.auth.token.auth_time ?? 0);
  const tokenAge = Math.floor(Date.now() / 1000) - authTime;
  if (!authTime || tokenAge > RECENT_LOGIN_SECONDS) {
    throw new HttpsError(
        "failed-precondition",
        "Recent authentication is required.",
    );
  }

  const database = getFirestore();

  try {
    // Todas as operações anteriores à remoção do Auth são idempotentes. Se uma
    // etapa falhar, o usuário ainda pode reautenticar e repetir a solicitação.
    await deleteStorageData(uid);
    await deleteQuery(
        database.collection("SolicitacoesAtivacao").where("userId", "==", uid),
    );
    await database.recursiveDelete(database.collection("Usuarios").doc(uid));
    await database.recursiveDelete(database.collection("usuarios").doc(uid));

    // Deve ser sempre a última operação: depois dela o usuário não poderá
    // autenticar novamente para retomar uma limpeza interrompida.
    await getAuth().deleteUser(uid);
    return {deleted: true};
  } catch (error) {
    logger.error("Account deletion failed", {
      error: error instanceof Error ? error.message : String(error),
    });
    throw new HttpsError(
        "internal",
        "Account deletion could not be completed.",
    );
  }
});
