exports.handler = async (event) => {
    console.log("Error detectado:", JSON.stringify(event, null, 2));
    return { statusCode: 200, body: "Error procesado" };
};