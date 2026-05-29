const admin =
    require("firebase-admin");

const axios =
    require("axios");

const {
  onCall,
  HttpsError,
} = require(
  "firebase-functions/v2/https"
);

const {
  defineSecret,
} = require(
  "firebase-functions/params"
);

admin.initializeApp();

/// 🔥 SECRETS
const TOKEN_METAX =
    defineSecret("TOKEN_METAX");

const PHONE_NUMBER_ID =
    defineSecret("PHONE_NUMBER_ID");

/// 🔥 ENVIAR PLANTILLAS
exports.enviarPlantillaConductores = onCall(

  {
    region: "us-central1",

    secrets: [
      TOKEN_METAX,
      PHONE_NUMBER_ID,
    ],
  },

  async (request) => {

    try {

      const telefono =
          request.data.telefono;

      const nombre =
          request.data.nombre;

      const plantilla =
          request.data.plantilla;

          const uid =
              request.data.uid;

      if (!telefono || !plantilla) {

        throw new HttpsError(
          "invalid-argument",
          "Faltan datos",
        );
      }

      const url =

          `https://graph.facebook.com/v22.0/${PHONE_NUMBER_ID.value()}/messages`;

          let mensajeGuardado = "";

          switch (plantilla) {

            case "agradecimiento_conductores_activos":

              mensajeGuardado =

                  `Hola ${nombre} 👋

          Queremos agradecerte porque hemos notado que has mantenido tu cuenta activa y te has conectado juiciosamente a Meta X durante estos días 🚕💜

          Conductores comprometidos como tú ayudan a mejorar el servicio y hacen crecer nuestra comunidad cada día 💪

          Gracias por seguir rodando con nosotros 🙌`;

              break;

            case "reactivacion_conductores":

              mensajeGuardado =

                  `Hola ${nombre} 👋

          Hemos notado que llevas algunos días sin conectarte a Meta X 🚕💜

          Queremos invitarte nuevamente a activar tu aplicación y seguir trabajando con nosotros 💪

          La ciudad sigue moviéndose y hay usuarios esperando conductores comprometidos como tú.

          Te esperamos nuevamente en línea 🙌`;

              break;

            case "seguimiento_conductores_inactivos":

              mensajeGuardado =

                  `Hola ${nombre} 👋

          Hace varios días no vemos actividad en tu cuenta de conductor Meta X 🚕

          Queremos saber si todo está bien y si podemos ayudarte en algo para que vuelvas a conectarte 💜

          Tu cuenta sigue activa y nos gustaría seguir contando contigo 💪

          Estamos atentos para apoyarte 🙌`;

              break;

            case "conductores_destacados":

              mensajeGuardado =

                  `🎉🥳 Hola ${nombre} 👋

          Queremos felicitarte porque eres uno de los conductores más comprometidos y activos de Meta X 🚕💜

          Tu constancia y dedicación ayudan a que cada vez más usuarios confíen en nuestra plataforma 💪

          Gracias por representar a Meta X cada día 🙌🎊`;

              break;
          }

      const response =
          await axios.post(

            url,

            {

              messaging_product:
                  "whatsapp",

              to: telefono,

              type: "template",

              template: {

                name: plantilla,

                language: {
                  code: "es",
                },

                components: [

                  {
                    type: "body",

                    parameters: [

                      {
                        type: "text",

                        text:
                            nombre || "Conductor",
                      },
                    ],
                  },
                ],
              },
            },

            {

              headers: {

                Authorization:
                    `Bearer ${TOKEN_METAX.value()}`,

                "Content-Type":
                    "application/json",
              },
            },
          );

      console.log(
        `✅ Plantilla enviada: ${plantilla} -> ${telefono}`
      );

      /// 🔥 GUARDAR CONVERSACIÓN
      await admin.firestore()

          .collection(
              "whatsapp_conversations_metax"
          )

          .doc(telefono)

          .set({

            phone: telefono,

            name: nombre || "Conductor",

           lastMessage:
           mensajeGuardado,

            lastMessageAt:
                admin.firestore
                    .FieldValue
                    .serverTimestamp(),

            from_me: true,

          }, { merge: true });


      /// 🔥 GUARDAR MENSAJE
      await admin.firestore()

          .collection(
              "whatsapp_messages_metax"
          )

          .add({

            conversationId:
                telefono,

           text:
           mensajeGuardado,

            from_me: true,

            timestamp:
                admin.firestore
                    .FieldValue
                    .serverTimestamp(),

            tipo:
                "template",

            plantilla,

          });

          /// 🔥 ACTUALIZAR HISTORIAL DEL CONDUCTOR
          await admin.firestore()

              .collection("drivers_inactivos")

              .doc(request.data.uid)

              .set({

                ultimaPlantilla:
                    plantilla,

                ultimoMensajeAt:
                    admin.firestore
                        .FieldValue
                        .serverTimestamp(),

                cantidadMensajes:
                    admin.firestore
                        .FieldValue
                        .increment(1),

                historialMensajes:

                    admin.firestore
                        .FieldValue
                        .arrayUnion({

                      plantilla:
                          plantilla,

                      fecha:
                          new Date(),

                    }),

              }, { merge: true });

      return response.data;

    } catch (error) {

      console.error(
        "❌ Error enviando plantilla",
        error?.response?.data || error,
      );

      throw new HttpsError(

        "internal",

        error?.response?.data?.error?.message ||

        "Error enviando plantilla",
      );
    }
  }
);