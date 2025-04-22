const functions = require("firebase-functions");
const admin = require("firebase-admin");
const moment = require("moment");

admin.initializeApp();

exports.notificarMatriculas = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
    const db = admin.firestore();
    const hoje = moment().format("YYYY-MM-DD"); // Data de hoje

    try {
        const snapshot = await db.collection("matriculas").get();

        if (snapshot.empty) {
            console.log("Nenhuma matrícula encontrada.");
            return null;
        }

        snapshot.forEach(async (doc) => {
            const dados = doc.data();
            const matriculaMesAno = dados.data_matricula; // Exemplo: "03/2024"
            const tokenFCM = dados.token_fcm;

            if (!matriculaMesAno || !tokenFCM) return;

            // Pegar primeiro dia do mês da matrícula
            const [mes, ano] = matriculaMesAno.split("/"); 
            const primeiroDiaMes = moment(`${ano}-${mes}-01`, "YYYY-MM-DD");

            // Calcular 15 dias antes do primeiro dia do mês
            const dataNotificacao = primeiroDiaMes.subtract(15, "days").format("YYYY-MM-DD");

            // Se a data atual for a data de notificação, enviamos a notificação
            if (hoje === dataNotificacao) {
                const message = {
                    token: tokenFCM,
                    notification: {
                        title: "Lembrete de Matrícula",
                        body: `Sua matrícula do mês ${matriculaMesAno} está chegando. Prepare-se!`,
                    },
                };

                await admin.messaging().send(message);
                console.log(`Notificação enviada para ${dados.nome}`);
            }
        });

        return null;
    } catch (error) {
        console.error("Erro ao enviar notificações:", error);
        return null;
    }
});
