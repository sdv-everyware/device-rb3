# dtb.img: Linaro's rule is gated on its own TARGET_DEVICE names; the same recipe for this one.
ifeq ($(TARGET_DEVICE),sdv_media_db845c)

SDV_MEDIA_DB845C_DTB := $(TARGET_KERNEL_DIR)/sdm845-db845c.dtb

$(PRODUCT_OUT)/dtb.img: $(SDV_MEDIA_DB845C_DTB)
	cat $(SDV_MEDIA_DB845C_DTB) > $@

droidcore: $(PRODUCT_OUT)/dtb.img

endif
